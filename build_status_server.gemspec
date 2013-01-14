$:.push File.expand_path("../lib", __FILE__)
require "build_status_server/version"

Gem::Specification.new do |s|
  s.name = "build_status_server"
  s.version = BuildStatusServer::VERSION
  s.platform = Gem::Platform::RUBY
  s.author = "Juan C. Muller"
  s.email  = "jcmuller@gmail.com"
  s.homepage = "http://github.com/jcmuller/build_status_server"
  s.license = "GPL"

  s.summary = <<-EOS
This utility is part of an XFD (eXtreeme Feedback Device) solution designed and
built for my employer ChallengePost (http://challengepost.com). It works in
conjunction with our Jenkins Continuous Integration server (and its
Notification Plugin)) and an Arduino powered Traffic Light controller
(https://github.com/jcmuller/TrafficLightController) with a pseudo-RESTful API.
  EOS
  s.description = "A build notifier server for Jenkins CI that controls an XFD over HTTP"

  s.files        = `git ls-files`.split($\) - %w(.rspec bin/test_tcp_server)
  s.require_path = "lib"
  s.bindir       = "bin"
  s.executables  = %w(build_status_server)

  s.homepage   = "http://github.com/jcmuller/build_status_server"
  s.test_files = Dir["spec/**/*_spec.rb"]

  s.add_development_dependency("guard")
  s.add_development_dependency("guard-bundler")
  s.add_development_dependency("guard-ctags-bundler")
  s.add_development_dependency("guard-rspec")
  s.add_development_dependency("pry-debugger")
  s.add_development_dependency("rake")
  s.add_development_dependency("sinatra")
  s.add_development_dependency("terminal-notifier-guard")

  s.add_dependency("command_line_helper")
  s.add_dependency("json")
end
