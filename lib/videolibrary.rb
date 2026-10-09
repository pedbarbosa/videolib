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
    @new_scans = 0
    tv_shows = scan_tv_shows
    progressbar = progressbar_create('Scanning', tv_shows.count)
    episodes = tv_shows.sort.each_with_object({}) do |show, scanned|
      progressbar_update(progressbar, show)
      scan_show(show, scanned)
    end
    progressbar.finish
    write_cache(episodes)

    create_html_report
  end

  private

  def scan_show(show, episodes)
    show_episodes(show).each do |file_path|
      scan_result = scan_media_if_new_or_changed(file_path, show)
      next if scan_result.nil?

      episodes[file_path.to_sym] = scan_result
      write_temporary_cache(episodes)
    end
  end

  def file_mtime_unchanged?(file_path, cached)
    File.mtime(file_path).to_i == cached.first['mtime']
  end

  def file_size_unchanged?(file_path, cached)
    File.size(file_path) == cached.first['size']
  end

  # Episodes moved into a season folder keep their cache entry, matched on show and file name
  def cached_episode(file_path, show)
    @cache_by_show_and_file ||= @cache.to_h { |path, episode| [[episode.first['show'], File.basename(path)], episode] }
    @cache[file_path] || @cache_by_show_and_file[[show, File.basename(file_path)]]
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
    cached = cached_episode(file_path, show)
    if cached && file_size_unchanged?(file_path, cached) && file_mtime_unchanged?(file_path, cached)
      puts "File '#{file_path}' hasn't changed" if @config['debug']
      cached
    else
      puts "File '#{file_path}' is new or has changed, scanning ..." if @config['debug']
      scan_new_or_changed_media(file_path, show)
    end
  end

  # Episodes sit in season folders ('<show>/Season 1/'), or directly in the show folder
  def show_episodes(show)
    show_path = File.join(@config['scan_path'], show)
    Dir.glob('**/*', base: show_path).filter_map do |file|
      file_path = "#{show_path}/#{file}"
      file_path if @config['video_extensions'].include?(File.extname(file)) && File.file?(file_path)
    end
  end

  def scan_tv_shows
    tv_shows = []
    Dir.foreach(@config['scan_path']) do |dir|
      next if @config['ignore_folders'].include?(dir) || !File.directory?(File.join(@config['scan_path'], dir))

      tv_shows << dir
    end
    puts "Found #{tv_shows.count} directories."
    tv_shows
  end
end
