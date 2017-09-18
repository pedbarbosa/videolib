#!/usr/bin/env ruby

require 'erb'
require 'json'
require 'mediainfo'
require 'ruby-progressbar'
require 'yaml'

CONFIG_FILE = ENV['HOME'] + '/.videolib.yml'
@config = YAML.load_file(CONFIG_FILE)

def exit_with_msg(m)
  puts("Error: #{m}")
  exit 1
end

def read_json(file)
  if File.file?(file)
    File.open(file, 'r') do |f|
      @episodes = JSON.parse(f.read)
    end
  else
    @episodes = {}
  end
end

def write_json(file)
  File.open(file + '.tmp', 'w') do |f|
    f.write(JSON.pretty_generate(@episodes))
  end
end

def scan_episode(show, name)
  info = Mediainfo.new name
  codec = info.video.format
  width = info.video.width
  height = info.video.height
  size = File.size(name)
  @episodes[name] = [show: show, codec: codec, width: width, height: height, size: size]
end

def scan_files(path, dir, progressbar)
  new_files = false
  progressbar.title = dir
  Dir.foreach(path + dir) do |file|
    if @config['video_extensions'].include? File.extname(file)
      name = path + dir + '/' + file
      # Check file info if not previously scanned
      unless @episodes[name]
        scan_episode(dir, name)
        new_files = true
      end
    end
  end
  write_json(@config['json_file']) if new_files
  progressbar.increment
end

def scan_path(path)
  unless File.directory?(path)
    exit_with_msg("#{path} is an invalid directory. Check your #{CONFIG_FILE} config file.")
  end

  @tv_shows = []
  Dir.foreach(path) do |dir|
    @tv_shows << dir unless @config['ignore_folders'].include? dir
  end
  puts "Found #{@tv_shows.count} directories, starting episode scan..."
  progressbar = ProgressBar.create(format: "Scanning '%t' |%b>%i| %c/%C",
                                   title: '...', starting_at: 0, total: @tv_shows.count)
  @tv_shows.each { |dir| scan_files(path, dir, progressbar) }
  progressbar.finish
end

def process_read
  removed = []
  check_for_changes(removed) unless @episodes.count.zero?
end

def check_for_changes(removed)
  puts "There are #{@episodes.count} episodes from previous scans, searching for removed episodes..."
  progressbar = ProgressBar.create(format: "Checking '%t' |%b>%i| %c/%C",
                                   title: '...', starting_at: 0, total: @episodes.count)
  @episodes.each do |key, values|
    progressbar.title = values.first['show']
    progressbar.increment
    unless File.file?(key) && File.size(key) == values.first['size']
      @episodes.delete(key)
      removed << key
    end
  end
  progressbar.finish
  if removed.empty?
    puts 'No changes to previously scanned episodes found.'
  else
    puts "Removed #{removed.count} episodes, which have been deleted or changed since last scan."
    write_json(@config['json_file'])
  end
end

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

def track_resolution(i)
  if i >= 800
    '1080p'
  elsif i < 800 && i >= 640
    '720p'
  elsif i < 640
    'sd'
  else
    ''
  end
end

def episode_badge(i)
  if (i.first['x265_1080p'] + i.first['x264_1080p']) == i.first['episodes']
    '1080p'
  elsif (i.first['x265_720p'] + i.first['x264_720p'] + i.first['mpeg_720p']) == i.first['episodes']
    '720p'
  elsif (i.first['x265_sd'] + i.first['x264_sd'] + i.first['mpeg_sd']) == i.first['episodes']
    'SD'
  else
    'Mix'
  end
end

def create_report
  html_table = ''
  recode_report = '<table border=1>'

  shows = {}
  @episodes.each do |key, value|
    show = value.first['show']
    if shows[show].nil?
      shows[show] = ['show_size' => 0, 'episodes' => 0, 'x265_episodes' => 0,
                     'x265_1080p' => 0, 'x265_720p' => 0, 'x265_sd' => 0,
                     'x264_1080p' => 0, 'x264_720p' => 0, 'x264_sd' => 0, 'mpeg_720p' => 0, 'mpeg_sd' => 0]
    end
    height = track_resolution(value.first['height'])
    size = value.first['size']

    # Process shows that are marked with override
    if @config['codec_override'].include? show
      format = 'x265_' + height
      shows[show].first['x265_episodes'] += 1
    else
      codec = track_codec(value.first['codec'])
      format = codec + '_' + height
      if codec == 'x265'
        shows[show].first['x265_episodes'] += 1
      else
        recode_report += "<tr><td align=center>#{codec}</td><td align=center>#{height}</td>
        <td align=right>#{size}</td><td>#{key}</td></tr>"
      end
    end

    shows[show].first[format] += 1
    shows[show].first['episodes'] += 1
    shows[show].first['show_size'] += size
  end

  total_x265 = total_size = 0
  shows.each do |key, value|
    show_size = value.first['show_size'] / 1024 / 1024
    total_size += show_size
    total_x265 += value.first['x265_episodes']
    html_table += "<tr><td class='left'>#{key}</td><td>#{show_size}</td>
    <td class='center'><progress max='#{value.first['episodes']}'
      value='#{value.first['x265_episodes']}'></progress></td>
    <td>#{value.first['episodes']}</td><td>#{episode_badge(value)}</td><td>#{value.first['x265_1080p']}</td>
    <td>#{value.first['x265_720p']}</td><td>#{value.first['x265_sd']}</td><td>#{value.first['x264_1080p']}</td>
    <td>#{value.first['x264_720p']}</td><td>#{value.first['x264_sd']}</td><td>#{value.first['mpeg_720p']}</td>
    <td>#{value.first['mpeg_sd']}</td></tr>"
  end

  x265_pct = ((total_x265.to_f * 100) / @episodes.count).round(2)
  total_stats = "Scanned #{shows.count} shows with #{@episodes.count} episodes (#{total_x265} in x265 format "
  total_stats += "- #{x265_pct}%). #{total_size / 1024} GB in total"
  puts "Finished full directory scan. #{total_stats}"

  File.open(@config['html_report'], 'w') do |f|
    erb = ERB.new(File.read('report.html.erb'))
    f.write(erb.result(binding))
  end

  File.open(@config['recode_report'], 'w') do |f|
    f.write(recode_report)
  end
end

### Start of code execution

# Read previous scans from JSON file
read_json(@config['json_file'])

# Remove files that no longer exist or have been changed
process_read

# Scan directory for TV shows and episodes
scan_path(@config['scan_path'])

# Create report
create_report
