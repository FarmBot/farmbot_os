require 'simplecov'

SimpleCov.start do
  add_filter "/spec/"
end

Dir["spec/fixtures/*.rb"].each { |f| load(f) }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
