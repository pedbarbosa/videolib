#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/videolibrary'

$stdout.sync = true

library = VideoLibrary.new
library.scan
