# frozen_string_literal: true

require 'json'
require 'open3'

# Adapter for the mediainfo CLI
class MediaInfoAdapter
  def initialize(filename)
    @filename = filename
    tracks = read_tracks
    @general = tracks.find { |track| track['@type'] == 'General' }
    @video = tracks.find { |track| track['@type'] == 'Video' }
  end

  def codec
    if @video.nil?
      puts "\nERROR: Corrupted metadata in file '#{@filename}', please check!"
      raise CorruptedFile
    end

    @video['Format']
  end

  def width
    Integer(@video['Width'], exception: false)
  end

  def height
    Integer(@video['Height'], exception: false)
  end

  def size
    @general['FileSize'].to_i
  end

  private

  # Passing the arguments separately runs mediainfo without a shell, so file names need no escaping.
  # Missing, unreadable and non-video files come back without a video track.
  def read_tracks
    output, = Open3.capture2('mediainfo', '--Output=JSON', @filename)
    JSON.parse(output).dig('media', 'track') || []
  end

  class CorruptedFile < StandardError
  end
end
