source 'https://rubygems.org'

gemspec

group :test do
  gem "rspec"
  #gem "ci_reporter"
  gem "simplecov", :require => false
  gem "simplecov-rcov"
  gem "coveralls"
end

group :development, :test do
  gem "rake"
end

group :development do
  gem "rb-fchange", require: false
  gem "rb-fsevent", require: false
  gem "rb-inotify", require: false
end
