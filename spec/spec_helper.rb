# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

# The codecov gem's upload only works from CircleCI, it crashes on GitHub Actions
if ENV['CIRCLECI'] == 'true'
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end
