# frozen_string_literal: true

require 'tmpdir'
require_relative '../../lib/html_reports'

describe 'lib/html_reports.rb' do
  let(:show) { [{ 'show_size' => 100, 'episodes' => 10, 'codec_resolution' => 5 }] }

  before do
    allow($stdout).to receive(:puts)
  end

  it 'returns the correct codec when show is overridden', :aggregate_failures do
    @config = { 'codec_override' => ['foo'] }
    expect(determine_or_override_codec_to_x265([{ 'show' => 'foo', 'codec' => 'XVID' }])).to eql('x265')
    expect(determine_or_override_codec_to_x265([{ 'show' => 'bar', 'codec' => 'XVID' }])).to eql('mpeg')
  end

  it 'outputs the codec_badge x265', :aggregate_failures do
    expect(codec_badge('HEVC')).to eql('x265')
    expect(codec_badge('V_MPEGH/ISO/HEVC')).to eql('x265')
    expect(codec_badge('hev1')).to eql('x265')
    expect(codec_badge('hvc1')).to eql('x265')
    expect(codec_badge('V_AV1')).to eql('x265')
  end

  it 'outputs the codec_badge x264', :aggregate_failures do
    expect(codec_badge('AVC')).to eql('x264')
    expect(codec_badge('V_MPEG4/ISO/AVC')).to eql('x264')
  end

  it 'outputs the codec_badge mpeg' do
    expect(codec_badge('MPEG something')).to eql('mpeg')
  end

  it 'outputs the codec_badge for AV1 and VP9 in any container', :aggregate_failures do
    %w[AV1 V_AV1 av01 VP9 V_VP9 vp09].each { |codec| expect(codec_badge(codec)).to eql('x265') }
  end

  it 'outputs the codec_badge for the integer codec IDs of MPEG-TS files', :aggregate_failures do
    expect(codec_badge(36)).to eql('x265')
    expect(codec_badge(27)).to eql('x264')
    expect(codec_badge(2)).to eql('mpeg')
  end

  it 'fails if codec_badge is invalid', :aggregate_failures do
    expect { codec_badge('123') }.to raise_error(InvalidCodec)
    expect { codec_badge(123) }.to raise_error(InvalidCodec)
    expect { codec_badge(nil) }.to raise_error(InvalidCodec)
  end

  it 'outputs the closest standard video resolution', :aggregate_failures do
    expect(track_resolution(nil, 'test')).to eql('sd')
    expect(track_resolution(500, 'test')).to eql('sd')
    expect(track_resolution(700, 'test')).to eql('720p')
    expect(track_resolution(820, 'test')).to eql('1080p')
  end

  it 'outputs the correct resolution for a preset badge', :aggregate_failures do
    expect(episode_badge_test('x265_1080p', 'x264_1080p')).to eql('1080p')
    expect(episode_badge_test('x265_720p', 'x264_720p')).to eql('720p')
    expect(episode_badge_test('x265_sd', 'x264_sd')).to eql('SD')
    expect(episode_badge_test('x264_720p', 'x264_sd')).to eql('Mix')
  end

  it 'increments the counter for a show' do
    increment_counters(show, 'codec_resolution', 100)
    expect(show).to eq([{ 'codec_resolution' => 6, 'episodes' => 11, 'show_size' => 200 }])
  end

  it 'raises error if codec or height are invalid', :aggregate_failures do
    expect { show_format('', '') }.to raise_error InvalidCodec
    expect { show_format('', '1080p') }.to raise_error InvalidCodec
    expect { show_format('x265', '') }.to raise_error InvalidHeight
  end

  it 'returns the correct badge for a show' do
    expect(show_format('x265', '1080p')).to eq('x265_1080p')
  end

  it 'creates report_row correctly' do
    report = new_show.first
    report['show_size'] = 123
    report['episodes'] = 7

    expect(report_row('abc', 123, report))
      .to match(/<td class='left'>abc.*<td>123.*<progress max="7" value="0">/m)
  end

  it 'generates report_summary correctly' do
    episodes = [{ 'show' => 'foo', 'codec' => 'x265' }, { 'show' => 'bar', 'codec' => 'x264' }]
    shows = [{ 'show_size' => 100, 'episodes' => 1 }, { 'show_size' => 200, 'episodes' => 2 }]

    expect(report_summary(1, episodes, shows, 1024))
      .to match 'Scanned 2 shows with 2 episodes (1 in x265 format - 50.0%). 1 GB in total'
  end

  describe '#create_html_report' do
    let(:out_dir) { Dir.mktmpdir }
    let(:config) do
      { 'json_file' => "#{out_dir}/videolib.json", 'html_report' => "#{out_dir}/index.html",
        'recode_report' => "#{out_dir}/recode.html", 'codec_override' => [], 'copy_override' => [] }
    end

    def cached_episode(show, codec, height)
      [{ 'show' => show, 'codec' => codec, 'height' => height, 'size' => 1_073_741_824, 'mtime' => 1_700_000_000 }]
    end

    before do
      @config = config
      episodes = {
        '/tv/Helix/Season 1/Helix - S01E01.mkv' => cached_episode('Helix', 'HEVC', 1080),
        '/tv/Helix/Season 2/Helix - S02E13.mkv' => cached_episode('Helix', 'AVC', 720),
        '/tv/Other/Other - S01E01.mkv' => cached_episode('Other', 'XVID', 480),
        '/tv/Broken/Broken - S01E01.mkv' => cached_episode('Broken', 'bogus', 1080)
      }
      write_json(config['json_file'], episodes)
      create_html_report
    end

    after { FileUtils.rm_rf(out_dir) }

    it 'writes a row per show and the totals', :aggregate_failures do
      report = File.read(config['html_report'])
      expect(report).to include("<td class='left'>Helix</td>", "<td class='left'>Other</td>")
      expect(report).to include('Scanned 3 shows with 4 episodes (1 in x265 format - 25.0%). 3 GB in total')
    end

    it 'lists the episodes that are not x265 for recoding', :aggregate_failures do
      recode = File.read(config['recode_report'])
      expect(recode).to include('Helix - S02E13.mkv', 'Other - S01E01.mkv')
      expect(recode).not_to include('Helix - S01E01.mkv')
    end

    it 'reports episodes with an invalid codec' do
      expect($stdout).to have_received(:puts)
        .with("Invalid codec 'bogus' detected on '/tv/Broken/Broken - S01E01.mkv'!")
    end

    context 'without a recode report configured' do
      let(:config) { super().except('recode_report') }

      it 'only writes the HTML report' do
        expect(Dir.children(out_dir)).to contain_exactly('videolib.json', 'index.html')
      end
    end
  end
end

def episode_badge_test(first, second)
  test = new_show
  test.first['episodes'] = 10
  test.first[first] = test.first[second] = 5
  episode_badge(test.first)
end
