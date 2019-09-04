# frozen_string_literal: true

require 'fileutils'
require 'json'

def read_json(file)
  if File.file?(file)
    File.open(file, 'r') do |f|
      JSON.parse(f.read)
    end
  else
    {}
  end
end

def write_file(file, contents)
  File.open(file + '.tmp', 'w') do |f|
    f.write(contents)
  end
  FileUtils.cp(file + '.tmp', file)
  FileUtils.remove(file + '.tmp')
rescue Interrupt
  puts 'Caught an interrupt request while file was being written, ignoring to maintain file integrity.'
end

def write_json(file, json)
  write_file(file, JSON.pretty_generate(json))
end
