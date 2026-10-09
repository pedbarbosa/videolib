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
