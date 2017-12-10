#!/usr/bin/env ruby
# frozen_string_literal: true

require 'ruby-progressbar'
require 'yaml'
require_relative 'lib/html_reports'
require_relative 'lib/mediainfo_wrapper'
require_relative 'lib/utils'

def scan_if_not_present(dir, name)
  return if @episodes[name]
  @episodes[name] = scan_episode(dir, name)
  true
end

def process_files(path, dir, progressbar)
  update_json = false
  Dir.foreach(path + dir) do |file|
    if @config['video_extensions'].include? File.extname(file)
      name = path + dir + '/' + file
      update_json = scan_if_not_present(dir, name)
    end
  end
  write_json(@config['json_file'], @episodes) if update_json
  progressbar_update(progressbar, dir)
end

def scan_path(path)
  exit_with_msg("Invalid directory '#{path}' in '#{CONFIG_FILE}' configuration file.") unless File.directory?(path)

  @tv_shows = []
  Dir.foreach(path) do |dir|
    @tv_shows << dir unless @config['ignore_folders'].include? dir
  end
  puts "Found #{@tv_shows.count} directories, starting episode scan..."
  progressbar = progressbar_create('Scanning', @tv_shows.count)
  @tv_shows.sort.each { |dir| process_files(path, dir, progressbar) }
  progressbar.finish
end

def process_read
  return if @episodes.count.zero?
  puts "There are #{@episodes.count} episodes from previous scans, searching for removed episodes..."
  check_for_changes
end

def process_removal(list)
  if list.empty?
    puts 'No changes to previously scanned episodes found.'
  else
    puts "Removed #{list.count} episodes, which have been deleted or changed since last scan."
    write_json(@config['json_file'], @episodes)
  end
end

def check_for_changes(removed = [])
  progressbar = progressbar_create('Checking', @episodes.count)
  @episodes.sort.each do |key, values|
    progressbar_update(progressbar, values.first['show'])
    unless File.file?(key) && File.size(key) == values.first['size']
      @episodes.delete(key)
      removed << key
    end
  end
  progressbar.finish
  process_removal(removed)
end

### Start of code execution
# Load configuration from YAML file
CONFIG_FILE = ENV['HOME'] + '/.videolib.yml'
@config = load_config(CONFIG_FILE)

# Read previous scans from JSON file
@episodes = read_json(@config['json_file'])

# Remove files that no longer exist or have been changed
process_read

# Scan directory for TV shows and episodes
scan_path(@config['scan_path'])

# Create reports
# TODO : Investigate error caused by removed episodes - 'read_json' below is a hack
@episodes = read_json(@config['json_file'])
create_html_report(@episodes, @config)
