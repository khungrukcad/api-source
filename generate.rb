require "dotenv"
require "json"
require "fileutils"
require "digest"
require_relative "lib/notify"

Dotenv.load(".env.default", ".env.secret")

providers = ENV["PROVIDERS"].split(" ")
soft_failures = []

web = "gen/#{ENV["VERSION"]}"
endpoint = "net"
path = "#{web}/#{endpoint}"
digests = {}

FileUtils.mkdir_p(path)

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
        json_string = `sh providers/#{key}/#{endpoint}.sh`
        raise "#{name}: #{endpoint}.sh failed or is missing" if !$?.success?

        json = nil
        begin
            json = JSON.parse(json_string)
        rescue
            raise "#{name}: invalid JSON"
        end

        # inject metadata
        json["build"] = ENV["MIN_BUILD"].to_i
        json["name"] = name

        json_string = json.to_json
        file = File.new("#{path}/#{resource}", "w")
        file << json.to_json
        file.close()

        # save JSON digest
        digests[key] = Digest::SHA1.hexdigest(json_string)

        puts "Completed!"
    rescue StandardError => msg

        # keep going
        soft_failures << name

        puts "Failed: #{msg}"
    end
}

# fail abruptly on JSON hijacking
providers.each { |name|
    next if soft_failures.include? name

    key = name.downcase
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
