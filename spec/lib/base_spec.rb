# frozen_string_literal: true

require_relative '../../lib/base'

describe 'lib/base.rb test' do
  it "Test 'base/scan_if_not_present'" do
    episodes = {
      '/directory/file.mkv': [
        {
          show: 'test',
          codec: 'HEVC',
          width: 1920,
          height: 960,
          size: 1
        }
      ]
    }
    expect(scan_if_not_present(episodes, 'test', '/directory/file.mkv')).to eql false
  end

  it "Test empty 'episodes' in 'process_read' function" do
    expect(process_read(nil, [])).to eql nil
  end
end
