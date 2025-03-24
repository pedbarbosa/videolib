# frozen_string_literal: true

require_relative '../../lib/config_handler'

class DummyClass
  include ConfigHandler
end

describe ConfigHandler do
  let(:dummy_instance) { DummyClass.new }
  let(:config_file) { File.join(Dir.home, '.videolib.yml') }

  describe '#load_configuration' do
    context 'when configuration file is missing' do
      before do
        allow(File).to receive(:file?).with(config_file).and_return(false)
      end

      it 'raises a ConfigurationFileMissing error' do
        expect { dummy_instance.send(:load_configuration) }.to raise_error(ConfigHandler::ConfigurationFileMissing)
      end
    end

    context 'when configuration file exists' do
      let(:config_data) { { 'scan_path' => '/valid/path' } }

      before do
        allow(File).to receive(:file?).with(config_file).and_return(true)
        allow(YAML).to receive(:load_file).with(config_file).and_return(config_data)
        allow(dummy_instance).to receive(:validate_path).with(config_file, '/valid/path')
      end

      it 'loads and returns the configuration' do
        expect(dummy_instance.send(:load_configuration)).to eq(config_data)
      end
    end
  end

  describe '#validate_path' do
    context 'when scan_path is a valid directory' do
      it 'does not raise an error' do
        allow(File).to receive(:directory?).with('/valid/path').and_return(true)
        expect { dummy_instance.send(:validate_path, config_file, '/valid/path') }.not_to raise_error
      end
    end

    context 'when scan_path is not a valid directory' do
      it 'raises an InvalidScanDirectory error' do
        allow(File).to receive(:directory?).with('/invalid/path').and_return(false)
        expect { dummy_instance.send(:validate_path, config_file, '/invalid/path') }.to raise_error(ConfigHandler::InvalidScanDirectory)
      end
    end
  end
end

