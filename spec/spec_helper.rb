# frozen_string_literal: true

require 'simplecov'
# Fail the run if any line or branch goes untested. cover also counts files no spec loads.
SimpleCov.start do
  cover '{adapters,lib}/**/*.rb'
  coverage :line, minimum: 100
  coverage :branch, minimum: 100
end

# The codecov gem's upload only works from CircleCI, it crashes on GitHub Actions
if ENV['CIRCLECI'] == 'true'
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end
