require "dotenv"
require "json"
require "fileutils"
require "digest"
require "nokogiri"
require_relative "lib/convert"
require_relative "lib/notify"

Dotenv.load(".env.default", ".env.secret")

providers_path = "providers/index.json"
providers_json = File.read(providers_path)
providers = JSON.parse(providers_json)

soft_failures = []
args = ARGV.join(" ")

web = "gen"
versions = ENV["VERSIONS"].split(" ").map(&:to_i)
min_ios = ENV["MIN_IOS"].split(" ").map(&:to_i)
min_macos = ENV["MIN_MACOS"].split(" ").map(&:to_i)
endpoint = "net"
digests = {}

providers.each { |map|
    key = map["name"]
    name = map["description"]

    # ensure that repo and submodules were not altered
    repo_status = `git status --porcelain`
    puts repo_status
    raise "Dirty git status" if !repo_status.empty?

    puts
    puts "====== #{name} ======"
    puts

    #puts "Deleting old JSON..."
    #rm -f "$WEB/$ENDPOINT/$JSON"
    puts "Scraping..."

    begin
        prefix = "providers/#{key}"
        system("cd #{prefix} && ./update-servers.sh") unless ARGV.include? "noupdate"

        json_string = `sh #{prefix}/#{endpoint}.sh #{args}`
        raise "#{name}: #{endpoint}.sh failed or is missing" if !$?.success?

        json_src = nil
        begin
            json_src = JSON.parse(json_string)
        rescue
            raise "#{name}: invalid JSON"
        end

        subjects = []
        versions.each_with_index { |v, i|
            json = convert(v, endpoint, json_src.dup)

            path = "#{web}/v#{v}/providers/#{key}"
            resource = "#{endpoint}.json"
            FileUtils.mkdir_p(path)

            # inject metadata
            if v == 3
                json["build"] = min_ios[i]
            else
                json["build"] = {
                    "ios": min_ios[i],
                    "macos": min_macos[i]
                }
            end
            json["name"] = key # lowercase

            json_v = json.to_json
            file = File.new("#{path}/#{resource}", "w")
            file << json_v
            file.close()

            subjects << json_v
        }

        # save JSON digest
        digests[key] = Digest::SHA1.hexdigest(subjects[0])

        puts "Completed!"
    rescue StandardError => msg

        # keep going
        soft_failures << name

        puts "Failed: #{msg}"
    end
}

# fail abruptly on JSON hijacking
providers.each { |map|
    name = map["description"]
    next if soft_failures.include? name
    key = map["name"]

    # v3 is the reference
    path_v3 = "#{web}/v3/providers/#{key}/#{endpoint}.json"
    subject = IO.binread(path_v3)
    md = Digest::SHA1.hexdigest(subject)
    raise "#{name}: corrupt digest" if md != digests[key]
}

# copy providers index
versions.each { |v|
    FileUtils.cp(providers_path, "#{web}/v#{v}/providers")
}

# succeed but notify soft failures
if !soft_failures.empty?
    puts
    puts "Notifying failed providers: #{soft_failures}"
    notify_failures(
        ENV["TELEGRAM_TOKEN"],
        ENV["TELEGRAM_CHAT"],
        soft_failures
    )
end
