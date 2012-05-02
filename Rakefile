#!/usr/bin/env rake

$:.push File.expand_path("../lib", __FILE__)

require "rspec/core/rake_task"
require "build_status_server/version"

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = "spec/**/*_spec.rb"
  spec.rspec_opts = ["--backtrace --format CI::Reporter::RSpec"]
end

desc "clean backup and swap files, and artifacts"
task :clean do
  require "fileutils"
  Dir["{**/*~,**/.*.sw?,coverage/**,spec/reports/**}"].each do |file|
    rm_rf file
  end
end

desc "build gem"
task :build => :clean do
  system "gem build build_status_server.gemspec"
end

desc "release gem"
task :release => :build do
  system "gem push build_status_server-#{BuildStatusServer::VERSION}.gem"
end

task :default => :spec
