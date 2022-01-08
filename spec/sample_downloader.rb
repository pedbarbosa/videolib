# frozen_string_literal: true

require 'down'

def media_sample
  unless File.exist?('/tmp/videolib_sample.mkv')
    puts('Downloading sample file ...')
    tempfile = Down.download('http://mirrors.standaloneinstaller.com/video-sample/small.mkv')
    FileUtils.mv(tempfile.path, '/tmp/videolib_sample.mkv')
  end

  { codec: 'V_MPEG4/ISO/AVC',
    height: 320,
    mtime: 1641664874,
    show: 'test',
    size: 176_123,
    width: 560 }
end
