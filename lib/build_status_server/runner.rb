module BuildStatusServer
  class Runner
    attr_reader :config, :store

    def initialize(options = {})
      @config = Config.new(options)
      @store = Store.new(@config, options)
    end

    def listen(run_forever = true)
      Thread.abort_on_exception = true

      udp_thread = Thread.start(UDPServer.new(config, store)) do |udp_server|
        udp_server.run_loop
      end

      tcp_thread = Thread.start(HTTPServer.new(config, store)) do |http_server|
        http_server.run_loop
      end

      while run_forever
        # Do absolutely nothing. Work is done by child threads
        sleep 0.1
      end
    rescue Interrupt
      puts "Killing threads..."
      udp_thread.send(:exit)
      tcp_thread.send(:exit)
    end

  end
end
