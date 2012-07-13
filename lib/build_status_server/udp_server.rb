module BuildStatusServer
  class UDPServer < Server

    def setup
      address, port = config.udp_server["address"], config.udp_server["port"]
      @server = UDPSocket.new

      begin
        server.bind(address, port)
      rescue Errno::EADDRINUSE
        address_in_use_error(address, port)
      rescue Errno::EADDRNOTAVAIL, SocketError
        address_not_available_error(address)
      end

      STDOUT.puts "Listening on UDP #{address}:#{port}" if config.verbose
    end

    def process
      data, addr = server.recvfrom(2048)

      if process_job(data)
        status = store.summary_statuses
        TCPClient.new(config).notify(status)
      end
    end

    def process_job(data = "{}")
      job = begin
              JSON.parse(data)
            rescue JSON::ParserError => ex
              STDERR.puts "Invalid JSON! (Or at least JSON wasn't able to parse it...)\nReceived: #{data}"
              return false
            end

      build_name = job["name"]

      unless should_process_build(build_name)
        STDOUT.puts "Ignoring #{build_name} (#{config.mask["regex"]}--#{config.mask["policy"]})" if config.verbose
        return false
      end

      if job.class != Hash or
        job["build"].class != Hash
        STDERR.puts "Pinged with an invalid payload"
        return false
      end

      phase  = job["build"]["phase"]
      status = job["build"]["status"]

      if phase == "FINISHED"
        STDOUT.puts "Got #{status} for #{build_name} on #{Time.now} [#{job_internals(job)}]" if config.verbose
        case status
        when "SUCCESS", "FAILURE"
          store[build_name] = status
          return true
        end
      else
        STDOUT.puts "Started for #{build_name} on #{Time.now} [#{job_internals(job)}]" if config.verbose
      end

      return false
    end

    def job_internals(job)
      "build=>#{job["build"]["number"]}".tap do |output|
        output.concat(", status=>#{job["build"]["status"]}") if job["build"]["status"]
      end
    end

    def should_process_build(build_name)
      # If mask exists, then ...
      ! (
        !!config.mask &&
        !!config.mask["regex"] &&
        ((config.mask["policy"] == "include" && build_name !~ config.mask["regex"]) ||
         (config.mask["policy"] != "include" && build_name =~ config.mask["regex"])
      ))
    end

  end
end
