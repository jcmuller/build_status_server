$:.push File.expand_path("../lib", __FILE__)
require "build_status_server/version"

Gem::Specification.new do |s|
  s.name = "build_status_server"
  s.version = BuildStatusServer::VERSION
  s.platform = Gem::Platform::RUBY

  s.author = "Juan C. Muller"
  s.email = "jcmuller@gmail.com"
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

  s.files = Dir["{lib/**/*,spec/**/*}"] + %w(
    Gemfile
    Gemfile.lock
    LICENSE
    README.md
    bin/build_status_server
    build_status_server.gemspec
    config/config-example.yml
  )

  s.require_path = "lib"
  s.bindir = "bin"
  s.executables = %w(build_status_server)

  s.homepage = "http://github.com/jcmuller/build_status_server"
  s.test_files = Dir["spec/**/*_spec.rb"]

  s.add_development_dependency("rake")
  s.add_development_dependency("ruby-debug19")
  s.add_development_dependency("sinatra")

  s.add_dependency("json")
end

