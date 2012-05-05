#!/usr/bin/env rake

$:.push File.expand_path("../lib", __FILE__)

require "rspec/core/rake_task"
require "build_status_server/version"
require "bundler/gem_tasks"

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = "spec/**/*_spec.rb"
  spec.rspec_opts = ["--backtrace --format CI::Reporter::RSpec"]
end

desc "Run rspec by default"
task :default => :spec
