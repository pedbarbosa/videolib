# frozen_string_literal: true

require_relative '../html_reports.rb'

describe 'test' do
  it 'Test track_codec output' do
    expect(track_codec('HEVC')).to eql('x265')
    expect(track_codec('AVC')).to eql('x264')
    expect(track_codec('MPEG something')).to eql('mpeg')
    expect(track_codec('something')).to eql('')
  end

  it 'Test track_resolution output' do
    # TODO: Check how to process stdout
    # STDOUT.should_receive(:puts).with("> Couldn't process test resolution, setting to 'SD'!")
    # expect(track_resolution(nil, 'test')).to eql('sd')
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

def episode_badge_test(a, b)
  test = new_show
  test.first['episodes'] = 10
  test.first[a] = test.first[b] = 5
  episode_badge(test)
end
