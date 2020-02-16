# frozen_string_literal: true

require 'yaml'
require_relative 'config_handler.rb'
require_relative 'json_utils'
require_relative '../adapters/mediainfo'
require_relative '../adapters/progressbar'

# Video Library
class VideoLibrary
  include ConfigHandler

  def initialize(**params)
    @config_file = params[:config_file] || ENV['HOME'] + '/.videolib.yml'
    @config = load_configuration
    load_cache
    validate_path(@config['scan_path'])
  end

  def scan
    episodes = {}
    @new_scans = 0
    tv_shows = scan_tv_shows
    progressbar = progressbar_create('Scanning', tv_shows.count)
    tv_shows.sort.each do |show|
      progressbar_update(progressbar, show)
      Dir.foreach(@config['scan_path'] + show) do |file|
        next unless @config['video_extensions'].include? File.extname(file)

        next if invalid_encoding?(file)

        file_path = @config['scan_path'] + show + '/' + file
        episodes[file_path.to_sym] = scan_media_if_new_or_changed(file_path, show)
        write_temporary_cache(episodes)
      end
    end
    progressbar.finish
    write_cache(episodes)
  end

  private

  def load_cache
    @cache = File.file?(@config['json_file']) ? read_json(@config['json_file']) : {}
    puts "Retrieved #{@cache.count} episodes from cache."
  end

  def write_cache(episodes)
    write_json(@config['json_file'], episodes)
    puts "Wrote #{episodes.count} episodes back to cache."
  end

  def write_temporary_cache(episodes)
    write_json("#{@config['json_file']}.tmp", episodes) if !@new_scans.zero? && (@new_scans % 50).zero?
  end

  def invalid_encoding?(file)
    if file.encoding.to_s == 'US-ASCII'
      false
    else
      puts "File '#{file}' has an unexpected encoding: #{file.encoding}"
      true
    end
  end

  def scan_media_if_new_or_changed(file_path, show)
    if @cache[file_path] && File.size(file_path) == @cache[file_path].first['size']
      @cache[file_path]
    else
      @new_scans += 1
      scan_media_file(file_path, show)
    end
  end

  def scan_media_file(file_path, show)
    media = scan_with_symlink(file_path)
    [
      show: show,
      codec: media.codec,
      width: media.width,
      height: media.height,
      size: media.size
    ]
  end

  def scan_with_symlink(file_path)
    scan_link = '/tmp/videolib_scan.mkv'
    File.unlink(scan_link) if File.symlink?(scan_link)
    File.symlink(file_path, scan_link)
    MediaInfoAdapter.new(scan_link)
  end

  def scan_tv_shows
    tv_shows = []
    Dir.foreach(@config['scan_path']) do |dir|
      tv_shows << dir unless @config['ignore_folders'].include? dir
    end
    puts "Found #{tv_shows.count} directories."
    tv_shows
  end
end
