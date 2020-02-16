# frozen_string_literal: true

require 'yaml'

# Video Library config handler
module ConfigHandler
  private

  def load_configuration
    config_file = ENV['HOME'] + '/.videolib.yml'

    unless File.file?(config_file)
      raise ConfigurationFileMissing, "'#{config_file}' is missing, please check the README file!"
    end

    config = YAML.load_file(config_file)
    validate_path(config_file, config['scan_path'])
    config
  end

  def validate_path(config_file, scan_path)
    return if File.directory?(scan_path)

    raise InvalidScanDirectory, "'#{scan_path}' defined in '#{config_file}' is not a directory!"
  end

  class ConfigurationFileMissing < StandardError
  end

  class InvalidScanDirectory < StandardError
  end
end
