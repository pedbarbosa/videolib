# frozen_string_literal: true

require 'mediainfo'

# Adapter for MediaInfo
class MediaInfoAdapter
  def initialize(filename)
    @media = MediaInfo.from(filename)
  end

  def codec
    raise CorruptedFile if @media.video.nil?

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
