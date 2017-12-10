# frozen_string_literal: true

require_relative '../lib/mediainfo_wrapper'

describe 'videolib.rb test' do
  # next if ENV['TRAVIS']
  it 'Test sample file' do
    sample = '/tmp/big_buck_bunny_720p_1mb.mkv'
    sample_details = [{ show: 'Test', codec: 'MPEG-4 Visual', width: 1280, height: 720, size: 1_052_413 }]
    unless File.exist?(sample)
      puts 'Downloading sample file ...'
      `wget -P /tmp http://www.sample-videos.com/video/mkv/720/big_buck_bunny_720p_1mb.mkv`
    end
    expect(scan_episode('Test', sample)).to eql(sample_details)
  end
end
