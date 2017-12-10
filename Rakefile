# frozen_string_literal: true

require_relative 'spec/spec_helper'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = Dir.glob('spec/**/html*_spec.rb')
  t.rspec_opts = '--format documentation'
end
task default: :spec
