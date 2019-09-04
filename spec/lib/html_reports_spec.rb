# frozen_string_literal: true

require_relative '../../lib/html_reports'

describe 'lib/html_reports.rb test' do
  it 'Test codec_badge output' do
    expect(codec_badge('HEVC')).to eql('x265')
    expect(codec_badge('V_MPEGH/ISO/HEVC')).to eql('x265')
    expect(codec_badge('hev1')).to eql('x265')
    expect(codec_badge('AVC')).to eql('x264')
    expect(codec_badge('V_MPEG4/ISO/AVC')).to eql('x264')
    expect(codec_badge('MPEG something')).to eql('mpeg')

    expect{codec_badge('123')}.to raise_error(InvalidCodec)
  end

  it 'Test track_resolution output' do
    # TODO: Check how to process stdout
    # STDOUT.should_receive(:puts).with("> Couldn't process test resolution, setting to 'SD'!")
    expect(track_resolution(nil, 'test')).to eql('sd')
    expect(track_resolution(500, 'test')).to eql('sd')
    expect(track_resolution(700, 'test')).to eql('720p')
    expect(track_resolution(800, 'test')).to eql('1080p')
  end

  it 'Test episode_badge output' do
    expect(episode_badge_test('x265_1080p', 'x264_1080p')).to eql('1080p')
    expect(episode_badge_test('x265_720p', 'x264_720p')).to eql('720p')
    expect(episode_badge_test('x265_sd', 'x264_sd')).to eql('SD')
    expect(episode_badge_test('x264_720p', 'x264_sd')).to eql('Mix')
  end
end

def episode_badge_test(first, second)
  test = new_show
  test.first['episodes'] = 10
  test.first[first] = test.first[second] = 5
  episode_badge(test.first)
end
