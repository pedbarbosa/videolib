# frozen_string_literal: true

require_relative '../lib/json_utils'

# Generates list of TV Episodes requiring x265 recoding
class RecodeReport
  def initialize(params)
    @config = params[:config]
    @recode = params[:recode]
  end

  def generate
    html_table = ''
    total_count = 0
    total_size = 0

    @recode.sort.each do |file, show, codec, height, size, mtime|
      html_table += recode_row(codec, height, bytes_to_mb(size), show, file, mtime) unless override_show?(show)
      total_count += 1
      total_size += size
    end
    html_table += recode_totals(total_count, bytes_to_mb(total_size))

    recode_report = generate_html(html_table)
    write_file(@config['recode_report'], recode_report)
  end

  private

  def override_show?(show)
    @config['copy_override'].include? show
  end

  def generate_html(html_table)
    erb = ERB.new(File.read('templates/recode.html.erb'))
    erb.result(binding)
  end

  def bytes_to_mb(size)
    size / 1024 / 1024
  end

  def recode_row(codec, height, size, show, file, mtime)
    erb = ERB.new(File.read('templates/recode_row.html.erb'))
    erb.result(binding)
  end

  def recode_totals(total_count, total_size)
    erb = ERB.new(File.read('templates/recode_totals.html.erb'))
    erb.result(binding)
  end
end
