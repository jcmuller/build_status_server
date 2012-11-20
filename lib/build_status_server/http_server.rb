module BuildStatusServer
  class HTTPServer < Server

    def setup
      address, port = config.tcp_server["address"], config.tcp_server["port"]
      @server = TCPServer.new(address, port)
      STDOUT.puts "Listening on TCP #{address}:#{port}" if config.verbose
    rescue Errno::EADDRINUSE
      address_in_use_error(address, port)
    rescue Errno::EADDRNOTAVAIL, SocketError
      address_not_available_error(address)
    end

    def process
      Thread.start(server.accept) do |request|
        process_request(request)
      end
    end

    private

    def process_request(request)
      request.print headers
      request.print body
      request.close
    end

    def headers
      "HTTP/1.1 200/OK\r\nContent-type:text/html\r\n\r\n"
    end

    def body
      <<-EOF
<html>
  <head>
    <meta http-equiv="refresh" content="5; url=http://#{config.tcp_server["address"]}:#{config.tcp_server["port"]}/">
  </head>
  <body>
    Build is #{build_status}
  </body>
</html>
      EOF
    end

    def build_status
      store.passing_builds? ? "passing" : "failing"
    end
  end
end
