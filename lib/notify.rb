require "dotenv"
require "net/http"

Dotenv.load(".env.default", ".env.secret")

def notify_failures(failures)
    template = "API generation failed for: %{providers}"
    vars = {
        :providers => failures.map { |name| "\"#{name}\"" }.join(",")
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
