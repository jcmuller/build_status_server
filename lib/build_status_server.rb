require "rubygems"
require "json"
require "socket"
require "timeout"
require "yaml"

module BuildStatusServer
  autoload :Server, 'build_status_server/server'
end
