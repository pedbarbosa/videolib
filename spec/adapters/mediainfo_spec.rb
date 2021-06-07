# frozen_string_literal: true

require_relative '../../adapters/mediainfo'

# rubocop:disable Metrics/BlockLength
describe MediaInfoAdapter do
  context 'with no input' do
    it 'fails and prints full message' do
      expect { described_class.new }.to raise_error(ArgumentError, /wrong number of arguments/)
    end
  end

  context 'with an URL input' do
    media = described_class.new('/tmp/videolib_sample.mkv')

    describe '::codec' do
      it 'should return the codec of the video' do
        expect(media.codec).to eq 'V_MPEG4/ISO/AVC'
      end
    end

    describe '::width' do
      it 'should return the width of the video' do
        expect(media.width).to eq 560
      end
    end

    describe '::height' do
      it 'should return the height of the video' do
        expect(media.height).to eq 320
      end
    end

    describe '::size' do
      it 'should return the size of the video' do
        expect(media.size).to eq 176_123
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
