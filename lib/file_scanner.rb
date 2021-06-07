# frozen_string_literal: true

require_relative '../adapters/mediainfo'

# Video Library file scanner
class FileScanner
  def scan_media_file(file_path, show)
    media = scan_with_symlink(file_path)
    scan_format(media, show)
  rescue MediaInfoAdapter::CorruptedFile
    puts "\nERROR: Corrupted metadata in file '#{file_path}', please check!"
  end

  def scan_with_symlink(file_path)
    scan_link = '/tmp/videolib_scan.mkv'
    File.unlink(scan_link) if File.symlink?(scan_link)
    File.symlink(file_path, scan_link)
    MediaInfoAdapter.new(scan_link)
  end

  private

  def scan_format(media, show)
    [
      show: show,
      codec: media.codec,
      width: media.width,
      height: media.height,
      size: media.size
    ]
  end
end
