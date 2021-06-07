# frozen_string_literal: true

require 'down'
require 'simplecov'
SimpleCov.start

if ENV['TRAVIS']
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

unless File.exist?('/tmp/videolib_sample.mkv')
  puts('Downloading sample file ...')
  tempfile = Down.download('http://mirrors.standaloneinstaller.com/video-sample/small.mkv')
  FileUtils.mv(tempfile.path, '/tmp/videolib_sample.mkv')
end
