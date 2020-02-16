# frozen_string_literal: true

# Video Library config handler
module ConfigHandler
  private

  def load_configuration
    unless File.file?(@config_file)
      raise ConfigurationFileMissing, "'#{@config_file}' is missing, please check the README file!"
    end

    YAML.load_file(@config_file)
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
