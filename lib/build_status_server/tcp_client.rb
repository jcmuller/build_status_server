module BuildStatusServer
  class TCPClient
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def notify(status)
      tcp_client = config.tcp_client
      tcp_client["attempts"] ||= 2

      attempts = 0
      light  = status ? tcp_client["pass"] : tcp_client["fail"]

      client = nil
      begin
        timeout(5) do
          attempts += 1
          client = TCPSocket.new(tcp_client["host"], tcp_client["port"])
          client.print "GET #{light} HTTP/1.0\n\n"
          answer = client.gets(nil)
          STDOUT.puts answer if config.verbose
        end
      rescue Timeout::Error => ex
        STDERR.puts "Error: #{ex} while trying to send #{light}"
        retry unless attempts > tcp_client["attempts"]
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH => ex
        wait = wait_for(attempts)
        STDERR.puts "Error: #{ex} while trying to send #{light}"
        STDERR.puts "Will wait for #{wait} seconds and try again..."
        # sleep 2 seconds the first attempt, 4 the next, 8 the following...
        sleep wait
        retry unless attempts > tcp_client["attempts"]
      rescue StandardError => ex
        STDERR.puts "There was an error, but we don't know how to handle it: (#{ex.class}) #{ex}"
      ensure
        client.close if client
      end
    end

    def wait_for(attempt = 1)
      return 60 if attempt > 5 # Cap at one minute wait
      2**attempt
    end
  end
end
