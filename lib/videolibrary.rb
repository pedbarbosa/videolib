# frozen_string_literal: true

require_relative '../adapters/mediainfo'
require_relative '../adapters/progressbar'
require_relative 'cache_handler.rb'
require_relative 'config_handler.rb'
require_relative 'html_reports'
require_relative 'json_utils'

# Video Library
class VideoLibrary
  include CacheHandler
  include ConfigHandler

  def initialize
    @config = load_configuration
    @cache = load_cache
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

    create_html_report
  end

  private

  def invalid_encoding?(file)
    if file.encoding.to_s == 'US-ASCII'
      false
    else
      puts "File '#{file}' has an unexpected encoding: #{file.encoding}"
      true
    end
  end

  def file_size_unchanged?(file_path)
    File.size(file_path) == @cache[file_path].first['size']
  end

  def scan_media_if_new_or_changed(file_path, show)
    if @cache[file_path] && file_size_unchanged?(file_path)
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
