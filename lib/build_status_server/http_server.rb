module BuildStatusServer
  class HTTPServer < Server

    def setup
      address, port = config.tcp_server["address"], config.tcp_server["port"]
      begin
        @server = TCPServer.new(address, port)
      rescue Errno::EADDRINUSE
        address_in_use_error(address, port)
      rescue Errno::EADDRNOTAVAIL, SocketError
        address_not_available_error(address)
      end

      STDOUT.puts "Listening on TCP #{address}:#{port}" if config.verbose
    end

    def process
      session = server.accept
      status = store.summary_statuses

      session.print "HTTP/1.1 200/OK\r\nContent-type:text/html\r\n\r\n"
      session.print <<-EOF
<html>
  <head>
    <!meta http-equiv="refresh" content="5; url=http://#{config.tcp_server["address"]}:#{config.tcp_server["port"]}/">
    <link rel='stylesheet' href='http://platform.assetspost.com/assets/groups/application.css'/>
  </head>
  <body>
    #{status}
  </body>
</html>
      EOF
      session.close
    end
  end
end
