require 'rest-client'
require 'timeout'

module BuildStatusServer
  class TCPClient
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def notify(status)
      @tcp_client = config.tcp_client
      @status = status
      tcp_client["attempts"] ||= 2

      timed_attempt_to_send_notification
    rescue Timeout::Error => ex
      STDERR.puts "Error: #{ex} while trying to send #{light}"
      retry unless attempt > tcp_client["attempts"]
    rescue RestClient::NotModified
      STDOUT.puts "Not changing"
    rescue StandardError => ex
      STDERR.puts "There was an error, but we don't know how to handle it: #{ex}"
    end

    def wait_for
      return 60 if attempt > 5 # Cap at one minute wait
      2 ** attempt
    end

    private

    attr_reader :tcp_client, :light, :status

    def timed_attempt_to_send_notification
      Timeout.timeout(5) do
        answer = send_notification_and_get_answer
        STDOUT.puts answer if config.verbose
      end
    end

    def send_notification_and_get_answer
      send_notification_and_get_answer_impl
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH => ex
      connection_error(ex)
      retry unless attempt > tcp_client["attempts"]
    end

    def send_notification_and_get_answer_impl
      @light = light_for_status
      @attempt = attempt + 1
      RestClient.get("http://#{tcp_client["host"]}:#{tcp_client["port"]}/#{light}")
    end

    def connection_error(ex)
      wait = wait_for
      STDERR.puts "Error: #{ex} while trying to send #{light}"
      STDERR.puts "Will wait for #{wait} seconds and try again..."
      # sleep 2 seconds the first attempt, 4 the next, 8 the following...
      sleep wait
    end

    def attempt
      @attempt ||= 0
    end

    def light_for_status
      status ? tcp_client["pass"] : tcp_client["fail"]
    end
  end
end
