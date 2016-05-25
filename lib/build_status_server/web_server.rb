require 'sinatra/base'

module BuildStatusServer
  class WebServer < Sinatra::Base

    set :bind, '0.0.0.0'
    set :port, 2222

    post "/" do
      request.body.rewind
      process
    end

    get "/" do
      "Build is #{build_status}"
    end

    private

    def setup
      server_settings = config.udp_server
      address, port = server_settings["address"], server_settings["port"]
      @server = UDPSocket.new
      server.bind(address, port)
      STDOUT.puts "Listening on UDP #{address}:#{port}" if config.verbose
    rescue Errno::EADDRINUSE
      address_in_use_error(address, port)
    rescue Errno::EADDRNOTAVAIL, SocketError
      address_not_available_error(address)
    end

    def process
      if process_job(request.body.read)
        status = store.passing_builds?
        TCPClient.new(config).notify(status)
      end
    end

    def process_job(data = "{}")
      job = parse_data(data)
      return false unless job

      if job.class != Hash
        STDERR.puts "Pinged with an invalid payload"
        return false
      end

      build_name = [
        job["repository"]["name"],
        job["branch"],
      ].join('-')

      if !should_process_build(build_name)
        STDOUT.puts "Ignoring #{build_name} (#{config.mask["regex"]}--#{config.mask["policy"]})" if config.verbose
        return false
      end

      phase = job["event"]
      status = job["status"]

      if phase == "stop"
        STDOUT.puts "Got #{status} for #{build_name} on #{Time.now} [#{job_internals(job)}]" if config.verbose
        case status
        when "passed", "failed"
          store[build_name] = status
          return true
        end
      else
        STDOUT.puts "Started for #{build_name} on #{Time.now} [#{job_internals(job)}]" if config.verbose
      end

      false
    end

    def parse_data(data)
      JSON.parse(data)
    rescue JSON::ParserError
      STDERR.puts(<<-EOE)
Invalid JSON! (Or at least our JSON parser wasn't able to parse it...)
Received: #{data}
      EOE
      false
    end

    def job_internals(job)
      "build=>#{job["session"]}".tap do |output|
        output.concat(", status=>#{job["status"]}") if job["status"]
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

    def build_status
      store.passing_builds? ? "passing" : "failing"
    end

    def config
      @config ||= Config.new
    end

    def store
      @store ||= Store.new(config)
    end
  end
end
