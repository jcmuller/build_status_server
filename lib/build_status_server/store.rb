module BuildStatusServer
  class Store
    def initialize(config, options = {})
      @config = config
      read
    end

    def read
      @store = begin
                 YAML.load_file(store_file)
               rescue
                 {}
               end
      @store = {} unless @store.class == Hash
    end

    def []=(name, status)
      read
      store[name] = status
      write
    end

    def write
      File.open(store_file, "w") do |file|
        file.flock(File::LOCK_EX)
        YAML.dump(store, file)
        file.flock(File::LOCK_UN)
      end
    end

    def passing_builds?
      read
      store.values.select{ |val| val !~ %r{(?:pass|SUCCESS)} }.empty?
    end

    private

    attr_reader :config, :store

    def store_file
      @store_file ||= config.store_file
    end
  end
end
