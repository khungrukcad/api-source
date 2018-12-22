require "dotenv"
require "json"
require_relative "notify"

Dotenv.load(".env.default", ".env.secret")

providers = ENV["PROVIDERS"].split(" ")
web = "$API_PATH/#{ENV["VERSION"]}"
failed = []

providers.each { |name|
    endpoint = "net"
    key = name.downcase
    resource = "#{key}.json"

    puts ""
    puts "====== #{name} ======"
    puts ""

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
    json["build"] = ENV["MIN_BUILD"]
    json["provider"] = name

    file = File.new("#{web}/#{endpoint}/#{resource}", "w")
    file << json.to_s
    file.close()

    puts "Completed!"
}

if !failed.empty?
    puts
    puts "Notifying failed providers: #{failed}"
    notify_failures(failed)
end
