# frozen_string_literal: true

require 'erb'
require_relative 'utils'

def track_codec(i)
  case i
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

def track_resolution(i, file)
  if i.nil?
    # TODO : Provide proper exception handling for this and track_codec
    puts "> Couldn't process #{file} resolution, setting to 'SD'!"
    'sd'
  elsif i < 640
    'sd'
  elsif i >= 640 && i < 800
    '720p'
  elsif i >= 800
    '1080p'
  end
end

def episode_badge(i)
  case i.first['episodes']
  when i.first['x265_1080p'] + i.first['x264_1080p']
    '1080p'
  when i.first['x265_720p'] + i.first['x264_720p'] + i.first['mpeg_720p']
    '720p'
  when i.first['x265_sd'] + i.first['x264_sd'] + i.first['mpeg_sd']
    'SD'
  else
    'Mix'
  end
end

def new_show
  ['show_size' => 0, 'episodes' => 0, 'x265_episodes' => 0,
   'x265_1080p' => 0, 'x265_720p' => 0, 'x265_sd' => 0,
   'x264_1080p' => 0, 'x264_720p' => 0, 'x264_sd' => 0, 'mpeg_720p' => 0, 'mpeg_sd' => 0]
end

def create_html_report(episodes, config)
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
      codec = track_codec(value.first['codec'])
      format = codec + '_' + height
      if codec == 'x265'
        shows[show].first['x265_episodes'] += 1
      else
        recode << [file, codec, height, size] unless size < 1_000_000_000
      end
    end

    shows[show].first[format] += 1
    shows[show].first['episodes'] += 1
    shows[show].first['show_size'] += size
  end

  total_x265 = total_size = 0
  shows.sort.each do |show, value|
    show_size = value.first['show_size'] / 1024 / 1024
    total_size += show_size
    total_x265 += value.first['x265_episodes']
    html_table += "<tr><td class='left'>#{show}</td><td>#{show_size}</td>
    <td class='center'><progress max='#{value.first['episodes']}'
      value='#{value.first['x265_episodes']}'></progress></td>
    <td>#{value.first['episodes']}</td><td>#{episode_badge(value)}</td><td>#{value.first['x265_1080p']}</td>
    <td>#{value.first['x265_720p']}</td><td>#{value.first['x265_sd']}</td><td>#{value.first['x264_1080p']}</td>
    <td>#{value.first['x264_720p']}</td><td>#{value.first['x264_sd']}</td><td>#{value.first['mpeg_720p']}</td>
    <td>#{value.first['mpeg_sd']}</td></tr>"
  end

  x265_pct = ((total_x265.to_f * 100) / episodes.count).round(2)
  total_stats = "Scanned #{shows.count} shows with #{episodes.count} episodes (#{total_x265} in x265 format "
  total_stats += "- #{x265_pct}%). #{total_size / 1024} GB in total"
  puts "Finished full directory scan. #{total_stats}"

  erb = ERB.new(File.read('report.html.erb'))
  write_file(config['html_report'], erb.result(binding))

  recode_list(recode, config) if config['recode_report']
end

def recode_report_line(codec, file, height, size)
  "<tr><td align=center>#{codec}</td><td align=center>#{height}</td>
   <td align=right>#{size}</td><td>#{file}</td></tr>"
end

def recode_list(recode, config)
  files_to_copy = []
  recode_report = '<table border=1>'
  recode.sort.each do |file, codec, height, size|
    recode_report += recode_report_line(codec, file, height, size)
    files_to_copy << file unless File.file?(config['recode_cp_target'] + File.basename(file))
  end
  recode_report += '</table>'
  write_file(config['recode_report'], recode_report)
  return if !files_to_copy.empty? && File.directory?(config['recode_cp_target'])
  copy_files(files_to_copy, config['recode_cp_target'], config['recode_disk'])
end
