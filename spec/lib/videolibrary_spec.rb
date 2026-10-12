# frozen_string_literal: true

require 'tmpdir'
require_relative '../media_sample'
require_relative '../../lib/videolibrary'

describe VideoLibrary do
  # Skip initialize, which reads ~/.videolib.yml and the JSON cache
  subject(:library) do
    described_class.allocate.tap do |lib|
      lib.instance_variable_set(:@config, config)
      lib.instance_variable_set(:@cache, cache)
      lib.instance_variable_set(:@new_scans, 0)
    end
  end

  let(:scan_path) { "#{Dir.mktmpdir}/" }
  let(:config) do
    { 'scan_path' => scan_path, 'ignore_folders' => ['.', '..', '.DS_Store'],
      'video_extensions' => ['.mkv', '.mp4'], 'debug' => false }
  end
  let(:cache) { {} }

  def add_file(path)
    file_path = "#{scan_path}#{path}"
    FileUtils.mkdir_p(File.dirname(file_path))
    FileUtils.cp(MEDIA_SAMPLE_PATH, file_path)
    file_path
  end

  after { FileUtils.rm_rf(scan_path) }

  describe '#show_episodes' do
    let!(:first_episode) { add_file('Helix/Season 1/Helix - S01E01 - Pilot HDTV-720p.mkv') }
    let!(:last_episode) { add_file('Helix/Season 2/Helix - S02E13 - O Brave New World HDTV-720p.mkv') }

    before do
      add_file('Helix/Season 1/Helix - S01E01 - Pilot HDTV-720p.en.srt')
      add_file('Helix/tvshow.nfo')
    end

    it 'finds episodes inside season folders' do
      expect(library.send(:show_episodes, 'Helix')).to eq([first_episode, last_episode])
    end

    it 'finds episodes directly in the show folder' do
      flat_episode = add_file('Helix/Helix - S03E01 - Flat HDTV-720p.mkv')
      expect(library.send(:show_episodes, 'Helix')).to contain_exactly(first_episode, last_episode, flat_episode)
    end
  end

  describe '#scan_media_if_new_or_changed' do
    let(:file_path) { add_file('Helix/Season 1/Helix - S01E01 - Pilot HDTV-720p.mkv') }
    let(:cached) { [{ 'show' => 'Helix', 'size' => File.size(file_path), 'mtime' => File.mtime(file_path).to_i }] }
    let(:cache) { { "#{scan_path}Helix/Helix - S01E01 - Pilot HDTV-720p.mkv" => cached } }

    before { allow(MediaScanner).to receive(:new) }

    it 'reuses the cache entry of an episode moved into a season folder', :aggregate_failures do
      expect(library.send(:scan_media_if_new_or_changed, file_path, 'Helix')).to eq(cached)
      expect(MediaScanner).not_to have_received(:new)
    end

    it 'rescans a moved episode that has changed' do
      cached.first['size'] += 1
      allow(MediaScanner).to receive(:new).and_return(instance_double(MediaScanner, scan_media_file: [media_sample]))
      expect(library.send(:scan_media_if_new_or_changed, file_path, 'Helix')).to eq([media_sample])
    end

    context 'with debug on' do
      let(:config) { super().merge('debug' => true) }

      it 'says when a file has not changed' do
        expect { library.send(:scan_media_if_new_or_changed, file_path, 'Helix') }
          .to output(/hasn't changed/).to_stdout
      end

      it 'says when a file is scanned' do
        cached.first['size'] += 1
        allow(MediaScanner).to receive(:new).and_return(instance_double(MediaScanner, scan_media_file: [media_sample]))
        expect { library.send(:scan_media_if_new_or_changed, file_path, 'Helix') }
          .to output(/is new or has changed.*Scanning/m).to_stdout
      end
    end
  end

  describe '#scan_new_or_changed_media' do
    it 'reports a corrupted file instead of failing' do
      file_path = add_file('Helix/Season 1/Helix - S01E02 - Broken HDTV-720p.mkv')
      File.write(file_path, 'not a video')
      expect { library.send(:scan_new_or_changed_media, file_path, 'Helix') }
        .to output(/ERROR: File '#{Regexp.escape(file_path)}' seems corrupted/).to_stdout
    end
  end

  describe '#scan' do
    subject(:library) { described_class.new }

    let(:home) { Dir.mktmpdir }
    let(:config) do
      super().merge('json_file' => "#{home}/videolib.json", 'html_report' => "#{home}/report/index.html",
                    'codec_override' => [])
    end

    let!(:episodes) do
      [add_file('Helix/Season 1/Helix - S01E01 - Pilot HDTV-720p.mkv'),
       add_file('Helix/Season 2/Helix - S02E13 - O Brave New World HDTV-720p.mkv')]
    end

    before do
      File.write("#{home}/.videolib.yml", config.to_yaml)
      allow(Dir).to receive(:home).and_return(home)
    end

    after { FileUtils.rm_rf(home) }

    it 'caches and reports the episodes in season folders', :aggregate_failures do
      expect { library.scan }.to output(/Scanned 1 shows with 2 episodes/).to_stdout
      expect(read_json(config['json_file']).keys).to match_array(episodes)
      expect(File.read(config['html_report'])).to include("<td class='left'>Helix</td>")
    end

    it 'leaves corrupted files out of the cache', :aggregate_failures do
      File.write(add_file('Helix/Season 1/Helix - S01E02 - Broken HDTV-720p.mkv'), 'not a video')
      expect { library.scan }.to output(/seems corrupted/).to_stdout
      expect(read_json(config['json_file']).keys).to match_array(episodes)
    end
  end

  context 'with a scan_path without a trailing slash' do
    let(:scan_path) { Dir.mktmpdir }

    before { allow($stdout).to receive(:puts) }

    it 'finds the shows and their episodes', :aggregate_failures do
      episode = add_file('/Helix/Season 1/Helix - S01E01 - Pilot HDTV-720p.mkv')
      expect(library.send(:scan_tv_shows)).to eq(['Helix'])
      expect(library.send(:show_episodes, 'Helix')).to eq([episode])
    end
  end

  describe '#scan_tv_shows' do
    before do
      add_file('Helix/Season 1/Helix - S01E01 - Pilot HDTV-720p.mkv')
      add_file('stray.mkv')
      allow($stdout).to receive(:puts)
    end

    it 'lists show folders only' do
      expect(library.send(:scan_tv_shows)).to eq(['Helix'])
    end
  end
end
