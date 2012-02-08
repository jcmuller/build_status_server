#/usr/bin/env ruby

require "rubygems"
require "json"
require "redis"
require "socket"
require "timeout"
require "yaml"
require "ruby-debug"

class UdpServer
  attr_reader :redis, :config, :key_name

  def initialize
    @redis    = Redis.new
    @config   = YAML.load_file(File.expand_path(".", "config.yml"))
    @key_name = "build_result"
  end

  def listen
    sock = UDPSocket.new
    udp_server = config['udp_server']
    sock.bind(udp_server['address'], udp_server['port'])

    while true
      data, addr = sock.recvfrom(2048)
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
      return false
    end

    build_name = job_status["name"]
    phase      = job_status["build"]["phase"]
    status     = job_status["build"]["status"]

    if phase == "FINISHED"
      case status
      when "SUCCESS", "FAILURE"
        redis.hset(key_name, build_name, status)
        return true
      end
    end
  end

  def process_all_statuses
    pass = true
    redis.hkeys(key_name).each do |build|
      val  = redis.hget(key_name, build)
      pass = pass && (val == "pass" || val == "SUCCESS")
    end

    pass
  end

  def notify(status)
    tcp_client = config["tcp_client"]

    begin
      timeout(5) do
        client = TCPSocket.new(tcp_client["host"], tcp_client["port"])
        light  = status ? tcp_client["pass"] : tcp_client["fail"]
        client.print "GET #{light} HTTP/1.0\n\n"
        answer = client.gets(nil)
        puts answer
        client.close
      end
    rescue
      puts "Error: #{$!}"
    end
  end
end

UdpServer.new.listen

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

