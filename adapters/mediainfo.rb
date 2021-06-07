# frozen_string_literal: true

require 'mediainfo'

# Adapter for MediaInfo
class MediaInfoAdapter
  def initialize(filename)
    @filename = filename
    @media = MediaInfo.from(@filename)
  end

  def codec
    if @media.video.nil?
      puts "\nERROR: Corrupted metadata in file '#{@filename}', please check!"
      raise CorruptedFile
    end

    @media.video.codecid
  end

  def width
    @media.video.width
  end

  def height
    @media.video.height
  end

  def size
    @media.general.filesize
  end

  class CorruptedFile < StandardError
  end
end
