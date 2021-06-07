# frozen_string_literal: true

require_relative '../../lib/file_scanner'

describe FileScanner do
  subject(:test) { described_class.new }

  it 'should fail if mediainfo results do not match' do
    result = test.scan_media_file('/tmp/videolib_sample.mkv', 'test')
    expect(result).to eq([{ codec: 'V_MPEG4/ISO/AVC',
                            height: 320,
                            show: 'test',
                            size: 176_123,
                            width: 560 }])
  end
end
