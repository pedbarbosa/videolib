# frozen_string_literal: true

require 'yaml'
require_relative 'json_utils'
require_relative '../adapters/mediainfo'
require_relative '../adapters/progressbar'
require_relative '../lib/html_reports'

# Video Library
class VideoLibrary
  def initialize(**params)
    @config_file = params[:config_file] || ENV['HOME'] + '/.videolib.yml'
    @config = load_configuration
    @cache = File.file?(@config['json_file']) ? read_json(@config['json_file']) : {}
    puts "Retrieved #{@cache.count} episodes from cache."
    validate_path(@config['scan_path'])
  end

  def scan
    episodes = {}
    tv_shows = scan_tv_shows
    puts "Found #{tv_shows.count} directories, starting episode scan..."
    progressbar = progressbar_create('Scanning', tv_shows.count)
    tv_shows.sort.each do |show|
      progressbar_update(progressbar, show)
      Dir.foreach(@config['scan_path'] + show) do |file|
        next unless @config['video_extensions'].include? File.extname(file)

        file_path = @config['scan_path'] + show + '/' + file
        episodes[file_path.to_sym] = scan_media_if_new_or_changed(file_path, show)
      end
    end
    progressbar.finish
    write_json(@config['json_file'], episodes)
    puts "Wrote #{episodes.count} episodes back to cache."

    create_html_report(@config)
  end

  private

  def scan_media_if_new_or_changed(file_path, show)
    if @cache[file_path] && File.size(file_path) == @cache[file_path].first['size']
      @cache[file_path]
    else
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
    tv_shows
  end

  def load_configuration
    unless File.file?(@config_file)
      raise ConfigurationFileMissing, "'#{@config_file}' is missing, please check the README file!"
    end

    YAML.load_file(@config_file)
  end

  def validate_path(path)
    return if File.directory?(path)

    raise InvalidScanDirectory, "'#{path}' defined in '#{@config_file}' is not a directory!"
  end

  class ConfigurationFileMissing < StandardError
  end

  class InvalidScanDirectory < StandardError
  end
end
