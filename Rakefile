#!/usr/bin/env rake

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = ['--backtrace --format CI::Reporter::RSpec']
end

task :default => :spec
