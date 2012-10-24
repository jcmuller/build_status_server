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
      Thread.start(server.accept) do |session|
        status = store.summary_statuses

        session.print headers
        session.print body(status)
        session.close

      end
    end

    private

    def headers
      "HTTP/1.1 200/OK\r\nContent-type:text/html\r\n\r\n"
    end

    def body(status)
      <<-EOF
<html>
  <head>
    <meta http-equiv="refresh" content="5; url=http://#{config.tcp_server["address"]}:#{config.tcp_server["port"]}/">
  </head>
  <body>
    Build is #{status ? "passing" : "failing"}
  </body>
</html>
      EOF
    end
  end
end
