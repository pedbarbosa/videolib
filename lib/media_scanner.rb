# frozen_string_literal: true

require_relative '../adapters/mediainfo'

# Video Library media scanner
class MediaScanner
  def scan_media_file(file_path, show)
    scan_link = '/tmp/videolib_scan.mkv'
    scan_create_symlink(file_path, scan_link)
    file_mtime = File.mtime(file_path).to_i
    result = scan_format(MediaInfoAdapter.new(scan_link), show, file_mtime)
    scan_remove_symlink(scan_link)
    result
  end

  private

  def scan_create_symlink(file_path, scan_link)
    scan_remove_symlink(scan_link)
    File.symlink(file_path, scan_link)
  end

  def scan_remove_symlink(scan_link)
    FileUtils.rm_f(scan_link)
  end

  def scan_format(media, show, file_mtime)
    [
      show:,
      codec: media.codec,
      width: media.width,
      height: media.height,
      size: media.size,
      mtime: file_mtime
    ]
  end
end
