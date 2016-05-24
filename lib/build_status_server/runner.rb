module BuildStatusServer
  class Runner
    attr_reader :config, :store

    def initialize(options = {})
      @config = Config.new(options)
      @store = Store.new(@config, options)
    end

    def listen(run_forever = true)
      WebServer.run!
    end

  end
end
