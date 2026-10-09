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
      show_episodes(show).each do |file_path|
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
    scanner = MediaScanner.new
    puts "Scanning '#{file_path}' ..." if @config['debug']
    result = scanner.scan_media_file(file_path, show)
    @new_scans += 1
    result
  rescue MediaInfoAdapter::CorruptedFile
    puts "ERROR: File '#{file_path}' seems corrupted, please check!"
  end

  def scan_media_if_new_or_changed(file_path, show)
    if @cache[file_path] && file_size_unchanged?(file_path) && file_mtime_unchanged?(file_path)
      puts "File '#{file_path}' hasn't changed" if @config['debug']
      @cache[file_path]
    else
      puts "File '#{file_path}' is new or has changed, scanning ..." if @config['debug']
      scan_new_or_changed_media(file_path, show)
    end
  end

  # Episodes sit in season folders ('<show>/Season 1/'), or directly in the show folder
  def show_episodes(show)
    show_path = "#{@config['scan_path']}#{show}"
    Dir.glob('**/*', base: show_path).filter_map do |file|
      file_path = "#{show_path}/#{file}"
      file_path if @config['video_extensions'].include?(File.extname(file)) && File.file?(file_path)
    end
  end

  def scan_tv_shows
    tv_shows = []
    Dir.foreach(@config['scan_path']) do |dir|
      next if @config['ignore_folders'].include?(dir) || !File.directory?(@config['scan_path'] + dir)

      tv_shows << dir
    end
    puts "Found #{tv_shows.count} directories."
    tv_shows
  end
end
