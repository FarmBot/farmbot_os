require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
end

require 'pry'
Dir['spec/fakes/**/*.rb'].each {|file| load file }
require_relative '../lib/farmbot-pi'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
