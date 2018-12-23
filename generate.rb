require "dotenv"
require "json"
require 'fileutils'
require_relative "lib/notify"

Dotenv.load(".env.default", ".env.secret")

providers = ENV["PROVIDERS"].split(" ")
web = "#{ENV["API_PATH"]}/#{ENV["VERSION"]}"
failed = []

endpoint = "net"
FileUtils.mkdir_p("#{web}/#{endpoint}")

providers.each { |name|
    key = name.downcase
    resource = "#{key}.json"

    puts
    puts "====== #{name} ======"
    puts

    #puts "Deleting old JSON..."
    #rm -f "$WEB/$ENDPOINT/$JSON"
    puts "Scraping..."

    json_string = `sh providers/#{key}/#{endpoint}.sh`
    if !$?.success?
        failed << name
        puts "Failed!"
        next
    end

    json = JSON.parse(json_string)

    # inject metadata
    json["build"] = ENV["MIN_BUILD"].to_i
    json["name"] = name

    file = File.new("#{web}/#{endpoint}/#{resource}", "w")
    file << json.to_json
    file.close()

    puts "Completed!"
}

if !failed.empty?
    puts
    puts "Notifying failed providers: #{failed}"
    notify_failures(
        ENV["TELEGRAM_TOKEN"],
        ENV["TELEGRAM_CHAT"],
        failed
    )
end
