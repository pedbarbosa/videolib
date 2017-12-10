# frozen_string_literal: true

require_relative '../lib/mediainfo_wrapper'

describe 'test' do
  it 'Test sample file' do
    sample = 'spec/sample.mkv'
    sample_details = [{ show: 'Test', codec: 'HEVC', width: 640, height: 352, size: 85_063_595 }]
    expect(scan_episode('Test', sample)).to eql(sample_details)
  end
end
