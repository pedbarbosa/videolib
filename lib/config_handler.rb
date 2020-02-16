# frozen_string_literal: true

require 'yaml'

# Video Library config handler
module ConfigHandler
  def initialize
    @config_file = ENV['HOME'] + '/.videolib.yml'
  end

  private

  def load_configuration
    unless File.file?(@config_file)
      raise ConfigurationFileMissing, "'#{@config_file}' is missing, please check the README file!"
    end

    config = YAML.load_file(@config_file)
    validate_path(config['scan_path'])
    config
  end

  def validate_path(path)
    return if File.directory?(path)

    raise InvalidScanDirectory, "'#{path}' defined in '#{@config_file}' is not a directory!"
  end

  class ConfigurationFileMissing < StandardError
  end

  class InvalidScanDirectory < StandardError
  end
end
