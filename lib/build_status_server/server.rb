module BuildStatusServer
  class Server
    attr_reader :config, :server, :store

    def initialize(config, store)
      @config = config
      @store = store
      setup
    end

    def setup
      raise "You have to implement setup"
    end

    def run_loop
      raise "You have to implement run_loop"
    end

    def address_in_use_error(address, port)
      STDERR.puts <<-EOT
There appears that another instance is running, or another process
is listening on the same port (#{address}:#{port})

      EOT
      exit
    end

    def address_not_available_error(address)
      STDERR.puts <<-EOT
The address configured is not available (#{address})

      EOT
      exit
    end

  end
end
