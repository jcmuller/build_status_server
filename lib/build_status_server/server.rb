module BuildStatusServer
  class Server
    attr_reader   :config, :store_file, :mask_policy, :verbose
    attr_accessor :store, :mask

    def initialize(options = {})
      load_config_file(options[:config])
      @verbose     = options[:verbose] || config["verbose"]
      @store_file  = File.expand_path(".", config["store"]["filename"])
      @mask        = Regexp.new(config["mask"]["regex"])
      @mask_policy = config["mask"]["policy"] || "exclude"
    end

    def load_store
      @store = begin
                 YAML.load_file(store_file)
               rescue
                 {}
               end
      @store = {} unless store.class == Hash
    end

    def listen
      sock = UDPSocket.new
      udp_server = config["udp_server"]
      sock.bind(udp_server["address"], udp_server["port"])

      puts "Listening on UDP #{udp_server["address"]}:#{udp_server["port"]}" if verbose

      while true
        data, addr = sock.recvfrom(2048)
        #require "ruby-debug"; debugger
        if process_job(data)
          status = process_all_statuses
          notify(status)
        end
      end

      sock.close
    end

    def process_job(data = "{}")
      job = JSON.parse(data)

      build_name = job["name"]

      unless should_process_build(build_name)
        STDOUT.puts "Ignoring #{build_name} (#{mask}--#{mask_policy})" if verbose
        return false
      end

      if job.class != Hash or
        job["build"].class != Hash
        STDERR.puts "Pinged with an invalid payload"
        return false
      end

      phase      = job["build"]["phase"]
      status     = job["build"]["status"]

      if phase == "FINISHED"
        STDOUT.puts "Got #{status} for #{build_name} on #{Time.now} [#{job.inspect}]" if verbose
        case status
        when "SUCCESS", "FAILURE"
          load_store
          store[build_name] = status
          File.open(store_file, "w") { |file| YAML.dump(store, file) }
          return true
        end
      else
        STDOUT.puts "Started for #{build_name} on #{Time.now} [#{job.inspect}]" if verbose
      end

      return false
    end

    # Ensure config file exists. If not, copy example into it
    def load_config_file(config_file)
      curated_file = nil

      if config_file
        f = File.expand_path(config_file)
        if File.exists?(f)
          curated_file = f
        else
          puts "Supplied config file (#{config_file}) doesn't seem to exist" if verbose
          exit
        end
      else
        locations_to_try = %w(
          ~/.config/build_status_server/config.yml
          config/config.yml
          /etc/build_status_server/config.yml
          /usr/local/etc/build_status_server/config.yml
        )

        locations_to_try.each do |possible_conf_file|
          f = File.expand_path(possible_conf_file)
          if File.exists?(f)
            puts "Using #{possible_conf_file}!" if verbose if verbose
            curated_file = f
            break
          end
        end

        puts <<-EOT
  Looks like there isn't an available configuration file for this program. You
  can create one in any of the following locations:

   #{locations_to_try.map{|l| File.expand_path(l)}.join("\n   ")}

   Here is a sample of the contents for that file:

#{File.open("#{File.dirname(File.expand_path(__FILE__))}/../../config/config-example.yml").read}

        EOT

        exit
      end

      puts "Using #{curated_file}!" if verbose
      @config = YAML.load_file(curated_file)
    end

    def should_process_build(build_name)
      # If mask exists, then ...
      ! (!!mask && ((mask_policy == "include" && build_name !~ mask) ||
                    (mask_policy != "include" && build_name =~ mask)))
    end

    def process_all_statuses
      pass = true

      @store.values.each do |val|
        pass &&= (val == "pass" || val == "SUCCESS")
      end

      pass
    end

    def notify(status)
      tcp_client = config["tcp_client"]

      attempts = 0
      light  = status ? tcp_client["pass"] : tcp_client["fail"]

      begin
        timeout(5) do
          attempts += 1
          client = TCPSocket.new(tcp_client["host"], tcp_client["port"])
          client.print "GET #{light} HTTP/1.0\n\n"
          answer = client.gets(nil)
          STDOUT.puts answer if verbose
          client.close
        end
      rescue Timeout::Error => ex
        STDERR.puts "Error: #{ex} while trying to send #{light}"
        retry unless attempts > 2
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH => ex
        STDERR.puts "Error: #{ex} while trying to send #{light}"
        STDERR.puts "Will wait for 2 seconds and try again..."
        sleep 2
        retry unless attempts > 2
      end
    end
  end
end

__END__

Example payload:
{
  "name":"test",
  "url":"job/test/",
  "build":{
    "full_url":"http://cronus.local:3001/job/test/20/",
    "number":20,
    "phase":"FINISHED",
    "status":"SUCCESS",
    "url":"job/test/20/"
  }
}

We're getting this error once in a while:
/usr/local/lib/ruby/1.8/timeout.rb:64:in `notify': execution expired (Timeout::Error)
        from /home/jcmuller/build_notifier/lib/server.rb:102:in `notify'
        from /home/jcmuller/build_notifier/lib/server.rb:33:in `listen'
        from bin/server:5

