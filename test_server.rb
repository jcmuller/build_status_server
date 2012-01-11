#/usr/bin/env ruby

require "rubygems"
require "sinatra"

set :logging, true

before do
  puts "[#{Time.now}] [test_server] #{request.path}"
end

get "/red" do
  "<html>red</html>"
end

get "/green" do
  "<html>green</html>"
end

