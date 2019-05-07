# frozen_string_literal: true

def download_sample
  puts 'Downloading sample file ...'
  `wget -P /tmp https://www.sample-videos.com/video123/mkv/720/big_buck_bunny_720p_1mb.mkv`
end

describe 'videolib.rb test' do
  it 'Test sample file' do
    sample = '/tmp/big_buck_bunny_720p_1mb.mkv'
    sample_details = [{ show: 'Test', codec: 'V_MPEG4/ISO/ASP', width: 1280, height: 720, size: 1_052_413 }]
    download_sample unless File.exist?(sample)

    require_relative '../lib/mediainfo_wrapper'
    episode = scan_episode('Test', sample)
    expect(episode).to eql(sample_details)

    require_relative '../lib/html_reports'
    expect(codec_badge(episode.first[:codec])).to eql('mpeg')
    expect(track_resolution(episode.first[:height], sample)).to eql('720p')
  end
end
