require "rubygems"
require "json"
require "socket"
require "timeout"
require "yaml"

module BuildStatusServer
  autoload :CLI,     'build_status_server/cli'
  autoload :Config,  'build_status_server/config'
  autoload :Server,  'build_status_server/server'
  autoload :VERSION, 'build_status_server/version'
end
