# frozen_string_literal: true

require_relative '../sample_downloader'
require_relative '../../adapters/mediainfo'

# rubocop:disable Metrics/BlockLength
describe MediaInfoAdapter do
  context 'with no input' do
    it 'fails and prints full message' do
      expect { described_class.new }.to raise_error(ArgumentError, /wrong number of arguments/)
    end
  end

  context 'with an URL input' do
    sample = media_sample
    media = described_class.new('/tmp/videolib_sample.mkv')

    describe '::codec' do
      it 'returns the codec of the video' do
        expect(media.codec).to eq sample[:codec]
      end
    end

    describe '::width' do
      it 'returns the width of the video' do
        expect(media.width).to eq sample[:width]
      end
    end

    describe '::height' do
      it 'returns the height of the video' do
        expect(media.height).to eq sample[:height]
      end
    end

    describe '::size' do
      it 'returns the size of the video' do
        expect(media.size).to eq sample[:size]
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
