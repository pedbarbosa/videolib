# frozen_string_literal: true

require 'fileutils'
require 'json'

def exit_with_msg(message)
  puts("Error: #{message}")
  exit 1
end

def load_config(file)
  exit_with_msg("Configuration file '#{file}' missing, please check template.") unless File.file?(file)
  YAML.load_file(file)
end

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
end

def write_json(file, json)
  write_file(file, JSON.pretty_generate(json))
end

def copy_files(files_to_copy, target, disk)
  files_to_copy.each do |file|
    diskspace = `df -m #{disk}`.split(/\b/)[24].to_i
    if diskspace > 10_000
      puts "Copying #{file} to #{target}..."
      FileUtils.cp(file, target)
    else
      exit_with_msg("File copy stopped, #{disk} is almost full.")
    end
  end
end
