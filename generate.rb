require "dotenv"
require "json"
require "fileutils"
require "digest"
require_relative "lib/convert"
require_relative "lib/notify"

Dotenv.load(".env.default", ".env.secret")

providers = ENV["PROVIDERS"].split(" ")
soft_failures = []
args = ARGV.join(" ")

web = "gen"
versions = ENV["VERSIONS"].split(" ").map(&:to_i)
min_builds = ENV["MIN_BUILDS"].split(" ").map(&:to_i)
endpoint = "net"
digests = {}

providers.each { |name|
    key = name.downcase
    resource = "#{key}.json"

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
        system("sh #{prefix}/update-servers.sh") unless ARGV.include? "noupdate"

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
            json = convert(v, endpoint, json_src)
            path = "#{web}/v#{v}/#{endpoint}"
            FileUtils.mkdir_p(path)

            # inject metadata
            json["build"] = min_builds[i]
            json["name"] = name

            json_v = json.to_json
            file = File.new("#{path}/#{resource}", "w")
            file << json_v
            file.close()

            subjects << json_v
        }

        # save JSON digest (v1)
        digests[key] = Digest::SHA1.hexdigest(subjects[0])

        puts "Completed!"
    rescue StandardError => msg

        # keep going
        soft_failures << name

        puts "Failed: #{msg}"
    end
}

# fail abruptly on JSON hijacking (v1 is the reference)
providers.each { |name|
    next if soft_failures.include? name

    key = name.downcase
    path = "#{web}/v1/#{endpoint}"
    resource = "#{key}.json"

    subject = IO.binread("#{path}/#{resource}")
    md = Digest::SHA1.hexdigest(subject)
    raise "#{name}: corrupt digest" if md != digests[key]
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
