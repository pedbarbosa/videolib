# frozen_string_literal: true

require 'mediainfo'

# Adapter for MediaInfo
class MediaInfoAdapter
  def initialize(filename)
    @media = MediaInfo.from(filename)
  end

  def codec
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
end
