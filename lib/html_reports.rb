# frozen_string_literal: true

require 'date'
require 'erb'
require_relative 'recode_report'
require_relative '../lib/json_utils'

# Video formats as mediainfo reports them, and the codec IDs that older cache entries hold
AVAILABLE_CODECS = {
  # Formats
  'HEVC' => 'x265',
  'AV1' => 'x265',
  'VP9' => 'x265',
  'AVC' => 'x264',
  # Matroska codec IDs
  'V_MPEGH/ISO/HEVC' => 'x265',
  'V_AV1' => 'x265',
  'V_VP9' => 'x265',
  'V_MPEG4/ISO/AVC' => 'x264',
  'V_MS/VFW/FOURCC / DIVX' => 'x264',
  # MP4 codec IDs
  'hev1' => 'x265',
  'hvc1' => 'x265',
  'av01' => 'x265',
  'vp09' => 'x265',
  'avc1' => 'x264',
  # MPEG-TS stream types
  '36' => 'x265',
  '27' => 'x264',
  '1' => 'mpeg',
  '2' => 'mpeg',
  '16' => 'mpeg',
  # AVI FourCCs
  'XVID' => 'mpeg'
}.freeze

# The mediainfo gem stored numeric codec IDs (MPEG-TS stream types) as integers, and some files have none
def codec_badge(codec)
  codec = codec.to_s
  if AVAILABLE_CODECS.include?(codec)
    AVAILABLE_CODECS[codec]
  elsif codec.include?('MPEG')
    'mpeg'
  else
    raise InvalidCodec
  end
end

CODEC_LABELS = { 'x265' => 'x265', 'x264' => 'x264', 'mpeg' => 'H.262' }.freeze
RESOLUTION_LABELS = { '2160p' => '2160p', '1080p' => '1080p', '720p' => '720p', 'sd' => 'SD' }.freeze

# One report column per codec and resolution, e.g. 'x265_1080p' => 'x265 1080p'
FORMAT_COLUMNS = CODEC_LABELS.flat_map do |codec, codec_label|
  RESOLUTION_LABELS.map { |resolution, label| ["#{codec}_#{resolution}", "#{codec_label} #{label}"] }
end.to_h.freeze

# Minimum width or height for each resolution. Width catches widescreen crops (1920x800 is 1080p),
# height catches anamorphic video (1440x1080 is 1080p)
RESOLUTION_MINIMUMS = { '2160p' => [3200, 1800], '1080p' => [1700, 1000], '720p' => [1100, 700] }.freeze

def track_resolution(width, height, filename)
  return unknown_resolution(filename) if width.nil? && height.nil?

  resolution, = RESOLUTION_MINIMUMS.find do |_, (min_width, min_height)|
    width.to_i >= min_width || height.to_i >= min_height
  end
  resolution || 'sd'
end

def unknown_resolution(filename)
  puts "> Invalid resolution for #{filename}, setting to 'SD'!"
  'sd'
end

def episode_badge(show)
  return '-' if show['episodes'].zero?

  resolution = RESOLUTION_LABELS.keys.find do |res|
    CODEC_LABELS.keys.sum { |codec| show["#{codec}_#{res}"] } == show['episodes']
  end
  resolution ? RESOLUTION_LABELS[resolution] : 'Mix'
end

def new_show
  [{ 'show_size' => 0, 'episodes' => 0, 'x265_episodes' => 0 }.merge(FORMAT_COLUMNS.keys.to_h { |key| [key, 0] })]
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
  shows, recode = tally_shows(episodes)
  html_table, total_x265, total_size = report_table(shows)

  total_stats = report_summary(total_x265, episodes, shows, total_size)
  write_html_report(html_table, total_stats)

  return unless @config['recode_report']

  recode_report = RecodeReport.new(config: @config, recode:)
  recode_report.generate
end

def tally_shows(episodes)
  shows = {}
  recode = []
  episodes.each do |file, episode|
    show_counters = shows[episode.first['show']] ||= new_show
    tally_episode(show_counters, recode, file, episode)
  rescue InvalidCodec
    puts "Invalid codec '#{episode.first['codec']}' detected on '#{file}'!"
  end
  [shows, recode]
end

def tally_episode(show_counters, recode, file, episode)
  height = track_resolution(episode.first['width'], episode.first['height'], file)
  codec = determine_or_override_codec_to_x265(episode)

  if codec == 'x265'
    show_counters.first['x265_episodes'] += 1
  else
    recode << recode_entry(file, episode.first, codec, height)
  end

  increment_counters(show_counters, show_format(codec, height), episode.first['size'])
end

def recode_entry(file, details, codec, height)
  mtime = Time.at(details['mtime']).strftime('%Y-%m-%d %H:%M')
  { file:, show: details['show'], codec:, height:, size: details['size'], mtime: }
end

def report_table(shows)
  html_table = ''
  total_x265 = total_size = 0
  shows.sort.each do |show, details|
    show_size = details.first['show_size'] / 1024 / 1024
    total_size += show_size
    total_x265 += details.first['x265_episodes']
    html_table += report_row(show, show_size, details.first)
  end
  [html_table, total_x265, total_size]
end

def write_html_report(html_table, total_stats)
  erb = ERB.new(File.read('templates/report.html.erb'))
  write_file(@config['html_report'], erb.result(binding))
end

def report_row(show, show_size, details)
  erb = ERB.new(File.read('templates/report_row.html.erb'))
  erb.result(binding)
end

class InvalidCodec < StandardError
end

class InvalidHeight < StandardError
end
