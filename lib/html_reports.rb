# frozen_string_literal: true

require 'date'
require 'erb'
require_relative 'recode_report'
require_relative '../lib/json_utils'

def available_codecs
  {
    'HEVC' => 'x265',
    'V_MPEGH/ISO/HEVC' => 'x265',
    'hev1' => 'x265',
    'hvc1' => 'x265',
    'V_AV1' => 'x265',
    'AVC' => 'x264',
    'avc1' => 'x264',
    'V_MPEG4/ISO/AVC' => 'x264',
    'XVID' => 'mpeg'
  }
end

def codec_badge(codec)
  if available_codecs.include?(codec)
    available_codecs[codec]
  elsif codec.include?('MPEG')
    'mpeg'
  else
    raise InvalidCodec
  end
end

def track_resolution(height, filename)
  raise InvalidHeight, "Invalid height for #{filename}" if height.nil?

  case height
  when 0...640
    'sd'
  when 640..800
    '720p'
  else
    '1080p'
  end
rescue InvalidHeight => e
  puts "> #{e.message}, setting to 'SD'!"
  'sd'
end

def episode_badge(show)
  case show['episodes']
  when show['x265_1080p'] + show['x264_1080p']
    '1080p'
  when show['x265_720p'] + show['x264_720p'] + show['mpeg_720p']
    '720p'
  when show['x265_sd'] + show['x264_sd'] + show['mpeg_sd']
    'SD'
  else
    'Mix'
  end
end

def new_show
  [
    'show_size' => 0, 'episodes' => 0, 'x265_episodes' => 0,
    'x265_1080p' => 0, 'x265_720p' => 0, 'x265_sd' => 0,
    'x264_1080p' => 0, 'x264_720p' => 0, 'x264_sd' => 0,
    'mpeg_1080p' => 0, 'mpeg_720p' => 0, 'mpeg_sd' => 0
  ]
end

def increment_counters(show, format, size)
  show.first[format] += 1
  show.first['episodes'] += 1
  show.first['show_size'] += size
end

def show_format(codec, height)
  raise InvalidCodec if codec == ''

  raise InvalidHeight if height == ''

  "#{codec}_#{height}"
end

def determine_or_override_codec_to_x265(value)
  @config['codec_override'].include?(value.first['show']) ? 'x265' : codec_badge(value.first['codec'])
end

def report_summary(total_x265, episodes, shows, total_size)
  x265_pct = ((total_x265.to_f * 100) / episodes.count).round(2)
  total_stats = "Scanned #{shows.count} shows with #{episodes.count} episodes (#{total_x265} in x265 format "
  total_stats += "- #{x265_pct}%). #{total_size / 1024} GB in total"
  puts "Finished full directory scan. #{total_stats}"
  total_stats
end

def create_html_report
  episodes = read_json(@config['json_file'])
  html_table = ''
  recode = []

  shows = {}
  episodes.each do |file, episode|
    show = episode.first['show']
    shows[show] = new_show if shows[show].nil?
    height = track_resolution(episode.first['height'], file)
    size = episode.first['size']
    codec = determine_or_override_codec_to_x265(episode)
    mtime = Time.at(episode.first['mtime']).strftime('%Y-%m-%d %H:%M')

    if codec == 'x265'
      shows[show].first['x265_episodes'] += 1
    else
      recode << { file:, show:, codec:, height:, size:, mtime: }
    end

    format = show_format(codec, height)
    increment_counters(shows[show], format, size)
  rescue InvalidCodec
    puts "Invalid codec '#{episode.first['codec']}' detected on '#{file}'!"
  end

  total_x265 = total_size = 0
  shows.sort.each do |show, details|
    show_size = details.first['show_size'] / 1024 / 1024
    total_size += show_size
    total_x265 += details.first['x265_episodes']
    html_table += report_row(show, show_size, details.first)
  end

  total_stats = report_summary(total_x265, episodes, shows, total_size)
  erb = ERB.new(File.read('templates/report.html.erb'))
  write_file(@config['html_report'], erb.result(binding))

  return unless @config['recode_report']

  recode_report = RecodeReport.new(config: @config, recode:)
  recode_report.generate
end

def report_row(show, show_size, details)
  erb = ERB.new(File.read('templates/report_row.html.erb'))
  erb.result(binding)
end

class InvalidCodec < StandardError
end

class InvalidHeight < StandardError
end
