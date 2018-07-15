# frozen_string_literal: true

describe 'videolib.rb test' do
  it 'Test sample file' do
    sample = '/tmp/big_buck_bunny_720p_1mb.mkv'
    sample_details = [{ show: 'Test', codec: 'MPEG-4 Visual', width: 1280, height: 720, size: 1_052_413 }]
    unless File.exist?(sample)
      puts 'Downloading sample file ...'
      `wget -P /tmp http://www.sample-videos.com/video/mkv/720/big_buck_bunny_720p_1mb.mkv`
    end

    require_relative '../lib/mediainfo_wrapper'
    episode = scan_episode('Test', sample)
    expect(episode).to eql(sample_details)

    require_relative '../lib/html_reports'
    expect(track_codec(episode.first[:codec])).to eql('mpeg')
    expect(track_resolution(episode.first[:height], sample)).to eql('720p')
  end
end