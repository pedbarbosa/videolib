#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/base'
require_relative 'lib/html_reports'
require_relative 'lib/mediainfo_wrapper'
require_relative 'lib/utils'

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
