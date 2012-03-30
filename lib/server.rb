#/usr/bin/env ruby

class Server
  attr_reader   :config, :store_file
  attr_accessor :store

  def initialize
    @config     = YAML.load_file(File.expand_path(".", "config/config.yml"))
    @store_file = File.expand_path(".", "out/build_result.yml")
  end

  def load_store
    @store      = begin
                    YAML.load_file(store_file)
                  rescue
                    {}
                  end
  end


  def listen
    sock = UDPSocket.new
    udp_server = config['udp_server']
    sock.bind(udp_server['address'], udp_server['port'])

    while true
      data, addr = sock.recvfrom(2048)
      #debugger
      if process_job(data)
        status = process_all_statuses
        notify(status)
      end
    end

    sock.close
  end

  def process_job(data = "{}")
    job_status = JSON.parse(data)

    if job_status.class != Hash or
      job_status["build"].class != Hash
      STDERR.puts "Pinged with an invalid payload"
      return false
    end

    build_name = job_status["name"]
    phase      = job_status["build"]["phase"]
    status     = job_status["build"]["status"]

    if phase == "FINISHED"
      STDOUT.puts "Got #{status} for #{build_name} on #{Time.now} [#{job_status.inspect}]"
      case status
      when "SUCCESS", "FAILURE"
        load_store
        store[build_name] = status
        File.open(store_file, "w") { |file| YAML.dump(store, file) }
        return true
      end
    else
      STDOUT.puts "Started for #{build_name} on #{Time.now} [#{job_status.inspect}]"
    end

    return false
  end

  def process_all_statuses
    pass = true

    @store.values.each do |val|
      pass = pass && (val == "pass" || val == "SUCCESS")
    end

    pass
  end

  def notify(status)
    tcp_client = config["tcp_client"]

    attempts = 0
    success = 0

    while success == 0 && attempts < 3
      begin
        timeout(5) do
          client = TCPSocket.new(tcp_client["host"], tcp_client["port"])
          light  = status ? tcp_client["pass"] : tcp_client["fail"]
          client.print "GET #{light} HTTP/1.0\n\n"
          answer = client.gets(nil)
          STDOUT.puts answer
          client.close
          success = 1
        end
      rescue Timeout::Error
        STDERR.puts "Error: #{$!}"
        attempts += 1
      rescue Errno::ECONNREFUSED
        STDERR.puts "Error: #{$!}"
        STDERR.puts "Will wait for 2 seconds and try again..."
        sleep 2
        attempts += 1
      end
    end
  end
end

__END__

# {
#   "name":"test",
#   "url":"job/test/",
#   "build":{
#     "full_url":"http://cronus.local:3001/job/test/20/",
#     "number":20,
#     "phase":"FINISHED",
#     "status":"SUCCESS",
#     "url":"job/test/20/"
#   }
# }

