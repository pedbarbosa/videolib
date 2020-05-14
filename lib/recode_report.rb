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
    @recode.sort.each do |file, show, codec, height, size|
      html_table += recode_row(codec, file, height, size) unless override_show?(show)
    end
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

  def recode_row(codec, file, height, size)
    erb = ERB.new(File.read('templates/recode_row.html.erb'))
    erb.result(binding)
  end
end
