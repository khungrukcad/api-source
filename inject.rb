require "json"

json = JSON.parse(STDIN.read())
min_build = ARGV[0].to_i
provider = ARGV[1]

json["build"] = min_build
json["name"] = provider

puts json.to_json
