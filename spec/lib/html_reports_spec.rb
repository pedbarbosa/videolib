# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
describe 'lib/html_reports.rb' do
  before do
    @show = [
      {
        'show_size' => 100,
        'episodes' => 10,
        'codec_resolution' => 5
      }
    ]
  end

  it 'Test codec override' do
    @config = { 'codec_override' => ['foo'] }
    expect(determine_or_override_codec_to_x265([{ 'show' => 'foo', 'codec' => 'XVID' }])).to eql('x265')
    expect(determine_or_override_codec_to_x265([{ 'show' => 'bar', 'codec' => 'XVID' }])).to eql('mpeg')
  end

  it 'Test codec_badge output' do
    expect(codec_badge('HEVC')).to eql('x265')
    expect(codec_badge('V_MPEGH/ISO/HEVC')).to eql('x265')
    expect(codec_badge('hev1')).to eql('x265')
    expect(codec_badge('AVC')).to eql('x264')
    expect(codec_badge('V_MPEG4/ISO/AVC')).to eql('x264')
    expect(codec_badge('MPEG something')).to eql('mpeg')

    expect { codec_badge('123') }.to raise_error(InvalidCodec)
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

  it 'Test increment_counters' do
    allow(increment_counters(@show, 'codec_resolution', 100))
    expect(@show).to eq([
                          {
                            'codec_resolution' => 6,
                            'episodes' => 11,
                            'show_size' => 200
                          }
                        ])
  end

  it 'Test show_format' do
    expect { show_format('', '') }.to raise_error InvalidCodec
    expect { show_format('', '1080p') }.to raise_error InvalidCodec
    expect { show_format('x265', '') }.to raise_error InvalidHeight

    expect(show_format('x265', '1080p')).to eq('x265_1080p')
  end

  it 'Test report_row' do
    report = new_show.first
    report['show_size'] = 123
    report['episodes'] = 7

    expect(report_row('abc', 123, report))
      .to match(/<td class='left'>abc.*<td>123.*<progress max="7" value="0">/m)
  end

  it 'Test report_summary' do
    total_x265 = 1
    episodes = [
      { 'show' => 'foo', 'codec' => 'x265' },
      { 'show' => 'bar', 'codec' => 'x264' }
    ]

    shows = [
      { 'show_size' => 100, 'episodes' => 1 },
      { 'show_size' => 200, 'episodes' => 2 }
    ]
    total_size = 1024

    expect(report_summary(total_x265, episodes, shows, total_size))
      .to match 'Scanned 2 shows with 2 episodes (1 in x265 format - 50.0%). 1 GB in total'
  end
end
# rubocop:enable Metrics/BlockLength

def episode_badge_test(first, second)
  test = new_show
  test.first['episodes'] = 10
  test.first[first] = test.first[second] = 5
  episode_badge(test.first)
end
