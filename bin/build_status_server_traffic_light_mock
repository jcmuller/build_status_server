#!/usr/bin/env ruby

require "rubygems"
require "sinatra"

#set :logging, true

before do
  STDERR.puts "[#{Time.now}] [test_server] #{request.path}"
end

get "/" do
  "<html>/</html>"
end

get /\/(red|green|yellow|alive|current|off)/ do |path|
  "<html>#{path}</html>"
end
