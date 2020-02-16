# frozen_string_literal: true

require 'erb'
require 'fileutils'
require_relative '../lib/json_utils'

def codec_badge(codec)
  codecs = {
    'HEVC' => 'x265',
    'V_MPEGH/ISO/HEVC' => 'x265',
    'hev1' => 'x265',
    'AVC' => 'x264',
    'V_MPEG4/ISO/AVC' => 'x264',
    'XVID' => 'mpeg'
  }
  if codecs.include?(codec)
    codecs[codec]
  elsif /MPEG/.match?(codec)
    'mpeg'
  else
    raise InvalidCodec
  end
end

def track_resolution(height, filename)
  if height.nil?
    # TODO : Provide proper exception handling for this
    puts "> Couldn't process #{filename} resolution, setting to 'SD'!"
    'sd'
  elsif height < 640
    'sd'
  elsif height >= 640 && height < 800
    '720p'
  elsif height >= 800
    '1080p'
  end
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
  ['show_size' => 0, 'episodes' => 0, 'x265_episodes' => 0,
   'x265_1080p' => 0, 'x265_720p' => 0, 'x265_sd' => 0,
   'x264_1080p' => 0, 'x264_720p' => 0, 'x264_sd' => 0,
   'mpeg_1080p' => 0, 'mpeg_720p' => 0, 'mpeg_sd' => 0]
end

def increment_counters(show, format, size)
  show.first[format] += 1
  show.first['episodes'] += 1
  show.first['show_size'] += size
end

def show_format(codec, height)
  raise InvalidCodec if codec == ''

  raise InvalidHeight if height == ''

  codec + '_' + height
end

def determine_or_override_codec_to_x265(value)
  @config['codec_override'].include?(value.first['show']) ? 'x265' : codec_badge(value.first['codec'])
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

    if codec == 'x265'
      shows[show].first['x265_episodes'] += 1
    else
      recode << [file, show, codec, height, size]
    end

    format = show_format(codec, height)
    increment_counters(shows[show], format, size)
  rescue InvalidCodec
    puts "Invalid codec '#{episode.first['codec']}' detected on '#{file}'!"
  end

  total_x265 = total_size = 0
  shows.sort.each do |show, name|
    show_size = name.first['show_size'] / 1024 / 1024
    total_size += show_size
    total_x265 += name.first['x265_episodes']
    html_table += report_row(show, show_size, name.first)
  end

  x265_pct = ((total_x265.to_f * 100) / episodes.count).round(2)
  total_stats = "Scanned #{shows.count} shows with #{episodes.count} episodes (#{total_x265} in x265 format "
  total_stats += "- #{x265_pct}%). #{total_size / 1024} GB in total"
  puts "Finished full directory scan. #{total_stats}"

  erb = ERB.new(File.read('templates/report.html.erb'))
  write_file(@config['html_report'], erb.result(binding))

  recode_list(recode, @config) if @config['recode_report']
end

def report_row(show, show_size, name)
  erb = ERB.new(File.read('templates/report_row.html.erb'))
  erb.result(binding)
end

def recode_row(codec, file, height, size)
  erb = ERB.new(File.read('templates/recode_row.html.erb'))
  erb.result(binding)
end

def recode_list(recode, config)
  files_to_copy = []
  recode_report = '<table border=1>'
  recode.sort.each do |file, show, codec, height, size|
    unless config['copy_override'].include? show
      recode_report += recode_row(codec, file, height, size)
      files_to_copy << file unless File.file?(config['recode_cp_target'] + File.basename(file.to_s))
    end
  end
  recode_report += '</table>'
  write_file(config['recode_report'], recode_report)
  return if files_to_copy.empty? || !File.directory?(config['recode_cp_target'])

  copy_files(files_to_copy, config['recode_cp_target'], config['recode_disk'])
end

def copy_files(files_to_copy, target, disk)
  files_to_copy.each do |file|
    next if File.exist?("#{target}/#{file}")

    diskspace = `df -m #{disk}`.split(/\b/)[24].to_i
    raise "ERROR: File copy stopped, #{disk} is almost full." unless diskspace > 10_000

    puts "Copying #{file} to #{target} ..."
    FileUtils.cp(file, target)
  end
end

class InvalidCodec < StandardError
end

class InvalidHeight < StandardError
end
