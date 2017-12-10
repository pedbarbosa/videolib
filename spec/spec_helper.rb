# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

if ENV['TRAVIS']
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end
