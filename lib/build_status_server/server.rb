module BuildStatusServer
  class Server
    attr_reader :config, :store, :udp_server

    def initialize(options = {})
      @config = Config.new
      config.load(options)
    end

    def listen(run_forever = true)
      setup_udp_server

      begin
        while run_forever
          process_loop
        end
      rescue Interrupt
        STDOUT.puts "Good bye."
        udp_server.close
        exit
      end
    end

    private

    def process_loop
      data, addr = udp_server.recvfrom(2048)

      if process_job(data)
        status = process_all_statuses
        notify(status)
      end
    end

    def setup_udp_server
      address, port = config.udp_server["address"], config.udp_server["port"]
      @udp_server = UDPSocket.new

      begin
        udp_server.bind(address, port)
      rescue Errno::EADDRINUSE
        STDERR.puts <<-EOT
There appears that another instance is running, or another process
is listening on the same port (#{address}:#{port})

        EOT
        exit
      rescue Errno::EADDRNOTAVAIL
        STDERR.puts <<-EOT
The address configured is not available (#{address})

        EOT
        exit
      end

      STDOUT.puts "Listening on UDP #{address}:#{port}" if config.verbose
    end

    def load_store
      @store = begin
                 YAML.load_file(config.store_file)
               rescue
                 {}
               end
      @store = {} unless store.class == Hash
    end


    def process_job(data = "{}")
      job = JSON.parse(data)

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
        # Got SUCCESS for topic_action_master on Tue May 01 12:02:31 -0400 2012 []
        STDOUT.puts "Got #{status} for #{build_name} on #{Time.now} [#{job_internals(job)}]" if config.verbose
        case status
        when "SUCCESS", "FAILURE"
          load_store
          store[build_name] = status
          File.open(config.store_file, "w") { |file| YAML.dump(store, file) }
          return true
        end
      else
        # Started for topic_action_master on Tue May 01 12:00:30 -0400 2012 [{"name"=>"topic_action_master", "url"=>"job/topic_action_master/", "build"=>{"number"=>98, "url"=>"job/topic_action_master/98/", "phase"= >"STARTED", "full_url"=>"http://ci.berman.challengepost.com/job/topic_action_master/98/"}}]
        # Started for topic_action_master on Tue May 01 12:02:31 -0400 2012 [{"name"=>"topic_action_master", "url"=>"job/topic_action_master/", "build"=>{"number"=>98, "url"=>"job/topic_action_master/98/", "status" =>"SUCCESS", "phase"=>"COMPLETED", "full_url"=>"http://ci.berman.challengepost.com/job/topic_action_master/98/"}}]
        STDOUT.puts "Started for #{build_name} on #{Time.now} [#{job_internals(job)}]" if config.verbose
      end

      return false
    end

    def job_internals(job)
      "build=>#{job["build"]["number"]}, status=>#{job["build"]["status"]}"
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

    def process_all_statuses
      pass = true

      store.values.each do |val|
        pass &&= (val == "pass" || val == "SUCCESS")
      end

      pass
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
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH => ex
        STDERR.puts "Error: #{ex} while trying to send #{light}"
        STDERR.puts "Will wait for 2 seconds and try again..."
        sleep 2
        retry unless attempts > tcp_client["attempts"]
      ensure
        client.close if client
      end
    end
  end
end
