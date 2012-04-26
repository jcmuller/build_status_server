$:.push File.expand_path("../lib", __FILE__)
require "build_status_server/version"

Gem::Specification.new do |s|
  s.name = "build_status_server"
  s.version = BuildStatusServer::VERSION
  s.platform = Gem::Platform::RUBY

  s.author = "Juan C. Muller"
  s.email = "jcmuller@gmail.com"
  s.homepage = "http://github.com/jcmuller/build_status_server"
  s.summary = "A build notifier server for Jenkins CI that controls an XFD over HTTP"
  s.description = "A build notifier server for Jenkins CI that controls an XFD over HTTP"

  s.files = Dir["{bin/*,lib/**/*,spec/**/*}"] + %w(config/config-example.yml LICENSE README.md Gemfile Gemfile.lock build_status_server.gemspec)

  s.bindir = "bin"
  s.executables = %w(build_status_server build_status_server_traffic_light_mock)
  s.require_path = "lib"

  s.homepage = "http://github.com/jcmuller/build_status_server"
  s.test_files = Dir["spec/**/*_spec.rb"]

  s.add_development_dependency("ruby-debug")

  s.add_dependency("json")
  s.add_dependency("sinatra")
end

