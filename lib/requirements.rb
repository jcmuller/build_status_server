require "rubygems"
require "bundler/setup"

Bundler.require(:default)

require "socket"
require "timeout"
require "yaml"

require File.expand_path(".", "lib/server")
