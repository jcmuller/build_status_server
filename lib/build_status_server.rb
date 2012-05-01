require "rubygems"
require "json"
require "socket"
require "timeout"
require "yaml"

module BuildStatusServer
  autoload :Config, 'build_status_server/config'
  autoload :Server, 'build_status_server/server'
end
