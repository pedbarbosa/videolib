# frozen_string_literal: true

# Video Library cache handler
module CacheHandler
  private

  def load_cache
    cache = File.file?(@config['json_file']) ? read_json(@config['json_file']) : {}
    puts "Retrieved #{cache.count} episodes from cache."
    cache
  end

  def write_cache(episodes)
    write_json(@config['json_file'], episodes)
    puts "Wrote #{episodes.count} episodes back to cache."
  end

  def write_temporary_cache(episodes)
    return unless !@new_scans.zero? && (@new_scans % 20).zero?

    write_json("#{@config['json_file']}.tmp", episodes)
  end
end
