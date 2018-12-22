require "dotenv"
require "net/http"

Dotenv.load(".env.default", ".env.secret")

def notify_failures(failures)
    template = <<MSG
Hi,

the API generation script failed for the following providers:

%{failure_list}

Cheers
MSG
    vars = {
        :failure_list => failures.map { |p| "- #{p}" }.join("\n")
    }
    message = template % vars

    uri = URI.parse("https://api.telegram.org/bot#{ENV["TELEGRAM_TOKEN"]}/sendMessage")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri.path)
    req.set_form_data({
        "chat_id" => ENV["TELEGRAM_CHAT"],
        "text" => message
    })

    #http.set_debug_output($stdout)
    resp = http.request(req)
    #p resp
end
