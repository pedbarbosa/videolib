# frozen_string_literal: true

require_relative '../../adapters/mediainfo'

describe MediaInfoAdapter do
  context 'with no input' do
    it 'fails and prints full message' do
      expect { described_class.new }.to raise_error(ArgumentError, /wrong number of arguments/)
    end
  end

  context 'with an URL input' do
    media = described_class.new('https://www.sample-videos.com/video123/mkv/720/big_buck_bunny_720p_1mb.mkv')

    describe '::codec' do
      it 'should return the codec of the video' do
        expect(media.codec).to eq 'V_MPEG4/ISO/ASP'
      end
    end

    describe '::width' do
      it 'should return the width of the video' do
        expect(media.width).to eq 1280
      end
    end

    describe '::height' do
      it 'should return the height of the video' do
        expect(media.height).to eq 720
      end
    end

    describe '::size' do
      it 'should return the size of the video' do
        expect(media.size).to eq 1_052_413
      end
    end
  end
end
