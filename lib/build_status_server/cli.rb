require 'getoptlong'

module BuildStatusServer
  class CLI
    attr_reader :options

    def initialize
      process_command_line_options
      BuildStatusServer::Server.new(options).listen
    end

    def process_command_line_options
      @options = {}

      possible_arguments = [
        ['--config',      '-c', GetoptLong::REQUIRED_ARGUMENT],
        ['--help',        '-h', GetoptLong::NO_ARGUMENT],
        ['--verbose',     '-v', GetoptLong::NO_ARGUMENT],
        ['--version',     '-V', GetoptLong::NO_ARGUMENT],
      ]

      GetoptLong.new(*possible_arguments).each do |opt, arg|
        case opt
        when '--help'
          show_help_and_exit
        when '--config'
          options[:config] = arg
        when '--verbose'
          options[:verbose] = true
        when '--version'
          puts get_version
          exit
        end
      end
    end

    def get_version
      <<-EOV
#{get_program_name}, version #{BuildStatusServer::VERSION}

(c) Juan C. Muller, 2012
http://github.com/jcmuller/build_status_server
  EOV
    end

    def show_help_and_exit
      puts <<-EOT
Usage: #{get_program_name} [options]

Options:
  -c, --config CONFIGURATION  Specify what configuration file to load
  -h, --help                  Display this very helpful text
  -v, --verbose               Be more informative about what's going on
  -V, --version               Print out current version info

#{get_version}
      EOT
      exit
    end

    def get_program_name
      File.basename($0)
    end
  end
end
