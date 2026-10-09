# frozen_string_literal: true

require_relative '../adapters/mediainfo'

# Video Library media scanner
class MediaScanner
  def scan_media_file(file_path, show)
    scan_format(MediaInfoAdapter.new(file_path), show, File.mtime(file_path).to_i)
  end

  private

  def scan_format(media, show, file_mtime)
    [
      {
        show:,
        codec: media.codec,
        width: media.width,
        height: media.height,
        size: media.size,
        mtime: file_mtime
      }
    ]
  end
end
