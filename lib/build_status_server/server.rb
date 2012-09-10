module BuildStatusServer
  class Server
    attr_reader :config, :server, :store

    def initialize(config, store, run_setup = true)
      @config = config
      @store = store
      setup if run_setup
    end

    def setup
      raise "You have to implement setup" if self.class != Server
    end

    def process
      raise "You have to implement process" if self.class != Server
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

    def run_loop(run_forever = true)
      while(run_forever)
        process
      end
    end
  end
end
