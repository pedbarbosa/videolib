#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/html_reports'
require_relative 'lib/videolibrary'

library = VideoLibrary.new
library.scan

# TODO: Update collection of functions to a class
create_html_report
