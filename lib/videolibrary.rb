# frozen_string_literal: true

require_relative '../adapters/progressbar'
require_relative 'cache_handler'
require_relative 'config_handler'
require_relative 'html_reports'
require_relative 'json_utils'
require_relative 'media_scanner'

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

        file_path = "#{@config['scan_path']}#{show}/#{file}"
        scan_result = scan_media_if_new_or_changed(file_path, show)
        unless scan_result.nil?
          episodes[file_path.to_sym] = scan_result
          write_temporary_cache(episodes)
        end
      end
    end
    progressbar.finish
    write_cache(episodes)

    create_html_report
  end

  private

  def file_mtime_unchanged?(file_path)
    File.mtime(file_path).to_i == @cache[file_path].first['mtime']
  end

  def file_size_unchanged?(file_path)
    File.size(file_path) == @cache[file_path].first['size']
  end

  def scan_new_or_changed_media(file_path, show)
    @new_scans += 1
    scanner = MediaScanner.new
    scanner.scan_media_file(file_path, show)
  end

  def scan_media_if_new_or_changed(file_path, show)
    if @cache[file_path] && file_size_unchanged?(file_path) && file_mtime_unchanged?(file_path)
      @cache[file_path]
    else
      scan_new_or_changed_media(file_path, show)
    end
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
