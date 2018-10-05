# frozen_string_literal: true

require 'mediainfo'

def scan_episode(show, filename)
  return unless file_exists?(filename)

  info = Mediainfo.new filename
  codec = info.video.format
  width = info.video.width
  height = info.video.height
  size = File.size(filename)
  [show: show, codec: codec, width: width, height: height, size: size]
end

def file_exists?(filename)
  File.file?(filename) ? true : false
end
