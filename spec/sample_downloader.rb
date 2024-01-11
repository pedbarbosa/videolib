# frozen_string_literal: true

require 'down'

def media_sample
  file_path = '/tmp/videolib_sample.mkv'
  unless File.exist?(file_path)
    puts('Downloading sample file ...')
    tempfile = Down.download('http://mirrors.standaloneinstaller.com/video-sample/small.mkv')
    FileUtils.mv(tempfile.path, file_path)
  end

  { show: 'test', width: 560, height: 320, size: 176_123,
    codec: 'V_MPEG4/ISO/AVC',
    mtime: File.mtime(file_path).to_i }
end
