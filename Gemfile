source 'https://rubygems.org'

group :test, :remote_test do
  gem 'pry-rails'
end

gemspec

gem 'jruby-openssl', :platforms => :jruby

group :test, :remote_test do
  # gateway-specific dependencies, keeping these gems out of the gemspec
  gem 'braintree', '>= 2.50.0'
end
