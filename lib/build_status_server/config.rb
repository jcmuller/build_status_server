module BuildStatusServer
  class Config
    attr_reader :config

    def initialize(options = {}, run_load = true)
      self.load(options) if run_load
    end

    # This is responsible of loading the config object
    def load(options = {})
      config = load_config_file(options[:config])
      import_config(config, options)
    end

    def store_file
      return File.expand_path(".", store["filename"]) if store
      nil
    end

    private

    # This will load the passed in config object into the config attribute
    def import_config(config = {}, options = {})
      config["verbose"] = options[:verbose] unless options[:verbose].nil?
      @config = config
    end

    # This is responsible to return a hash with the contents of a YAML file
    def load_config_file(config_file = nil)
      curated_file = nil

      if config_file
        f = File.expand_path(config_file)
        if File.exists?(f)
          curated_file = f
        else
          raise "Supplied config file (#{config_file}) doesn't seem to exist"
        end
      else
        locations_to_try.each do |possible_conf_file|
          f = File.expand_path(possible_conf_file)
          if File.exists?(f)
            curated_file = f
            break
          end
        end

        if curated_file.nil?
          show_config_file_suggestion

          return YAML.load(get_example_config)
        end
      end

      YAML.load_file(curated_file).tap do |config|
        raise "This is an invalid configuration file!" unless config.class == Hash
      end
    end

    def show_config_file_suggestion
      STDERR.puts <<-EOT
Looks like there isn't an available configuration file for this program.
We're very diligently going to use some sensible defaults, but you're
strongly recommended to create one in any of the following locations:

    #{locations_to_try.join("\n    ")}

 Here is a sample of the contents for that file (and the settings we're going
 to use):

#{get_example_config}

Also, you can specify what configuration file to load by passing --config as an
argument (see "build_status_server --help")

      EOT
    end

    def locations_to_try
        %w(
          ~/.config/build_status_server/config.yml
          /etc/build_status_server/config.yml
          /usr/local/etc/build_status_server/config.yml
        )
    end

    def get_example_config
      filename = "#{File.dirname(File.expand_path(__FILE__))}/../../config/config-example.yml"
      File.open(filename).read
    end

    def method_missing(method_name, *args, &block)
      config.has_key?(method_name.to_s) ? config[method_name.to_s] : super
    end

    def respond_to_missing?(method_name, *args)
      config.has_key?(method_name.to_s)
    end

  end
end
