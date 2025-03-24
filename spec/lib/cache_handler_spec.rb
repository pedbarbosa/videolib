# frozen_string_literal: true

require_relative '../../lib/cache_handler'

class DummyClass
  include CacheHandler
  attr_accessor :config, :new_scans

  def initialize
    @config = { 'json_file' => '/path/to/cache.json' }
    @new_scans = 0
  end

  def read_json(file)
    JSON.parse(File.read(file))
  end

  def write_json(file, data)
    File.write(file, data.to_json)
  end
end

describe CacheHandler do
  let(:dummy_instance) { DummyClass.new }
  let(:json_file) { '/path/to/cache.json' }
  let(:temp_json_file) { '/path/to/cache.json.tmp' }
  let(:episodes) { [{ title: 'Episode 1' }, { title: 'Episode 2' }] }

  before do
    allow($stdout).to receive(:puts)
  end

  describe '#load_cache' do
    context 'when cache file exists' do
      before do
        allow(File).to receive(:file?).with(json_file).and_return(true)
        allow(dummy_instance).to receive(:read_json).with(json_file).and_return(episodes)
      end

      it 'loads cache from JSON file' do
        expect(dummy_instance.send(:load_cache)).to eq(episodes)
      end
    end

    context 'when cache file does not exist' do
      before do
        allow(File).to receive(:file?).with(json_file).and_return(false)
      end

      it 'returns an empty hash' do
        expect(dummy_instance.send(:load_cache)).to eq({})
      end
    end
  end

  describe '#write_cache' do
    before do
      allow(dummy_instance).to receive(:write_json).with(json_file, episodes)
    end

    it 'writes episodes to the cache file' do
      expect { dummy_instance.send(:write_cache, episodes) }.not_to raise_error
    end
  end

  describe '#write_temporary_cache' do
    context 'when new_scans is a multiple of 20' do
      before do
        dummy_instance.new_scans = 20
        allow(dummy_instance).to receive(:write_json).with(temp_json_file, episodes)
      end

      it 'writes temporary cache' do
        expect { dummy_instance.send(:write_temporary_cache, episodes) }.not_to raise_error
      end
    end

    context 'when new_scans is not a multiple of 20' do
      before do
        dummy_instance.new_scans = 15
      end

      it 'does not write temporary cache' do
        expect(dummy_instance).not_to receive(:write_json)
        dummy_instance.send(:write_temporary_cache, episodes)
      end
    end
  end
end

