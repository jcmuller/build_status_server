require 'getoptlong'
require 'command_line_helper'

module BuildStatusServer
  class CLI
    include CommandLineHelper::HelpText

    attr_reader :options

    def initialize
      set_program_name
      begin
        process_command_line_options
      rescue GetoptLong::MissingArgument
        puts
        show_help_and_exit
      end

      BuildStatusServer::Server.new(options).listen
    end

    private

    def options_possible
      [
        ['--config',  '-c', GetoptLong::REQUIRED_ARGUMENT, 'Override the configuration file location'],
        ['--help',    '-h', GetoptLong::NO_ARGUMENT, 'Show this text'],
        ['--verbose', '-v', GetoptLong::NO_ARGUMENT, ''],
        ['--version', '-V', GetoptLong::NO_ARGUMENT, 'Show version info'],
      ]
    end

    def process_command_line_options
      @options = {}

      cli_options.each do |opt, arg|
        case opt
        when '--help'
          show_help_and_exit
        when '--config'
          options[:config] = arg
        when '--verbose'
          options[:verbose] = true
        when '--version'
          puts version_info
          exit
        end
      end
    end

    def cli_options
      @cli_options ||= GetoptLong.new(*options_possible.map{ |o| o.first(3) })
    end

    def version_info
      <<-EOV
#{program_name}, version #{VERSION}

(c) Juan C. Muller, 2012
http://github.com/jcmuller/build_status_server
  EOV
    end

    def show_help_and_exit
      STDOUT.puts help_info
      exit
    end

    def set_program_name
      $0 = "#{File.basename($0)} (#{VERSION})"
    end
  end
end
