# frozen_string_literal: true

require_relative '../sample_downloader'
require_relative '../../lib/media_scanner'

describe MediaScanner do
  subject(:test) { described_class.new }

  it 'should fail if mediainfo results do not match' do
    sample = media_sample
    result = test.scan_media_file('/tmp/videolib_sample.mkv', 'test')
    expect(result).to eq([sample])
  end
end
