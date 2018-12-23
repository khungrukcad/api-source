require "net/http"

def notify_failures(token, chat, failures)
    template = "API generation failed for: %{providers}"
    vars = {
        :providers => failures.map { |name| "\"#{name}\"" }.join(", ")
    }
    message = template % vars

    uri = URI.parse("https://api.telegram.org/bot#{token}/sendMessage")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri.path)
    req.set_form_data({
        "chat_id" => chat,
        "text" => message
    })

    #http.set_debug_output($stdout)
    resp = http.request(req)
    #p resp
end
