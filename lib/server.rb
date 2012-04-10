require File.expand_path(".", "lib/requirements")

class Server
  attr_reader   :config, :store_file
  attr_accessor :store

  def initialize
    @store_file = File.expand_path(".", config["store"])
    @config      = YAML.load_file(config_file)
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

  # Ensure config file exists. If not, copy example into it
  def config_file
    File.expand_path(".", "config/config.yml").tap do |file|
      FileUtils.copy(File.expand_path(".", "config/config-example.yml"), file) unless File.exist?(file)
    end
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
        STDOUT.puts answer
        client.close
      end
    rescue StandardError => ex
      STDERR.puts "Error: #{ex} while trying to send #{light}"

      case ex.class.name
      when "Timeout::Error"
        # Just handle the timeouts
      when "Errno::ECONNREFUSED", "Errno::EHOSTUNREACH"
        STDERR.puts "Will wait for 2 seconds and try again..."
        sleep 2
      else
        throw ex
      end

      retry unless attempts > 2
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
