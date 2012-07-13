module BuildStatusServer
  class Store
    attr_reader :store, :config

    def initialize(options = {})
      @config = Config.new(options)
      read
    end

    def read
      @store = begin
                 YAML.load_file(config.store_file)
               rescue
                 {}
               end
      @store = {} unless store.class == Hash
    end

    def []=(name, status)
      read
      store[name] = status
      write
    end

    def write
      File.open(config.store_file, "w") do |file|
        file.flock(File::LOCK_EX)
        YAML.dump(store, file)
        file.flock(File::LOCK_UN)
      end
    end

    def summary_statuses
      read
      pass = true

      store.values.each do |val|
        pass &&= (val == "pass" || val == "SUCCESS")
      end

      pass
    end
  end
end
