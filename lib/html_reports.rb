# frozen_string_literal: true

require 'erb'
require_relative 'utils'

def codec_badge(codec)
  case codec
  when 'HEVC'
    'x265'
  when 'AVC'
    'x264'
  when /MPEG/
    'mpeg'
  else
    ''
  end
end

def track_resolution(height, filename)
  if height.nil?
    # TODO : Provide proper exception handling for this and track_codec
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
  case show.first['episodes']
  when show.first['x265_1080p'] + show.first['x264_1080p']
    '1080p'
  when show.first['x265_720p'] + show.first['x264_720p'] + show.first['mpeg_720p']
    '720p'
  when show.first['x265_sd'] + show.first['x264_sd'] + show.first['mpeg_sd']
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
rescue NoMethodError
  puts "Invalid format found: #{format}"
  puts show.first
end

def report_row(show, show_size, value)
  "<tr><td class='left'>#{show}</td><td>#{show_size}</td>
    <td class='center'><progress max='#{value.first['episodes']}'
      value='#{value.first['x265_episodes']}'></progress></td>
    <td>#{value.first['episodes']}</td><td>#{episode_badge(value)}</td>
    <td>#{value.first['x265_1080p']}</td><td>#{value.first['x265_720p']}</td><td>#{value.first['x265_sd']}</td>
    <td>#{value.first['x264_1080p']}</td><td>#{value.first['x264_720p']}</td><td>#{value.first['x264_sd']}</td>
    <td>#{value.first['mpeg_720p']}</td><td>#{value.first['mpeg_sd']}</td></tr>"
end

def create_html_report(config, episodes)
  html_table = ''
  recode = []

  shows = {}
  episodes.each do |file, value|
    show = value.first['show']
    shows[show] = new_show if shows[show].nil?
    height = track_resolution(value.first['height'], file)
    size = value.first['size']

    # Process shows that are marked with override
    if config['codec_override'].include? show
      format = 'x265_' + height
      shows[show].first['x265_episodes'] += 1
    else
      codec = codec_badge(value.first['codec'])
      format = codec + '_' + height
      if codec == 'x265'
        shows[show].first['x265_episodes'] += 1
      else
        recode << [file, show, codec, height, size] # unless size < 1_000_000_000
      end
    end

    increment_counters(shows[show], format, size)
  end

  total_x265 = total_size = 0
  shows.sort.each do |show, value|
    show_size = value.first['show_size'] / 1024 / 1024
    total_size += show_size
    total_x265 += value.first['x265_episodes']
    html_table += report_row(show, show_size, value)
  end

  x265_pct = ((total_x265.to_f * 100) / episodes.count).round(2)
  total_stats = "Scanned #{shows.count} shows with #{episodes.count} episodes (#{total_x265} in x265 format "
  total_stats += "- #{x265_pct}%). #{total_size / 1024} GB in total"
  puts "Finished full directory scan. #{total_stats}"

  erb = ERB.new(File.read('templates/report.html.erb'))
  write_file(config['html_report'], erb.result(binding))

  recode_list(recode, config) if config['recode_report']
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
      files_to_copy << file unless File.file?(config['recode_cp_target'] + File.basename(file))
    end
  end
  recode_report += '</table>'
  write_file(config['recode_report'], recode_report)
  return if files_to_copy.empty? || !File.directory?(config['recode_cp_target'])

  copy_files(files_to_copy, config['recode_cp_target'], config['recode_disk'])
end
