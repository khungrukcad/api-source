require "dotenv"
require "json"
require "fileutils"
require_relative "lib/notify"

Dotenv.load(".env.default", ".env.secret")
providers = ENV["PROVIDERS"].split(" ")
soft_failures = []

web = "gen/#{ENV["VERSION"]}"
endpoint = "net"
path = "#{web}/#{endpoint}"
FileUtils.mkdir_p(path)

providers.each { |name|
    key = name.downcase
    resource = "#{key}.json"

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

        file = File.new("#{path}/#{resource}", "w")
        file << json.to_json
        file.close()

        puts "Completed!"
    rescue StandardError => msg

        # keep going
        soft_failures << name

        puts "Failed: #{msg}"
    end
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
