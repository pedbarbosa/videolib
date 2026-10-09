# frozen_string_literal: true

require_relative '../media_sample'
require_relative '../../lib/media_scanner'

describe MediaScanner do
  subject(:test) { described_class.new }

  it 'fails if mediainfo results do not match' do
    sample = media_sample
    result = test.scan_media_file(MEDIA_SAMPLE_PATH, 'test')
    expect(result).to eq([sample])
  end
end
