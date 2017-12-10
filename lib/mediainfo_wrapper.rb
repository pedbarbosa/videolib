# frozen_string_literal: true

require 'mediainfo'

def scan_episode(show, name)
  info = Mediainfo.new name
  codec = info.video.format
  width = info.video.width
  height = info.video.height
  size = File.size(name)
  [show: show, codec: codec, width: width, height: height, size: size]
end
