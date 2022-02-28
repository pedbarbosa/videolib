#!/usr/bin/env ruby
# frozen_string_literal: true

require 'colorize'
require 'nokogiri'
require 'open-uri'
require 'yaml'
require_relative 'helpers/mysql2'

def load_configuration
  config_file = "#{ENV['HOME']}/.imdb_update.yml"

  unless File.file?(config_file)
    puts "'#{config_file}' is missing, please check the README file!"
    exit 1
  end

  YAML.load_file(config_file)
end

def fetch_page(link)
  @imdb_page = Nokogiri::HTML(URI.parse(link).open)
end

def imdb_title
  @imdb_page.at("//head/meta[@name='title']")['content'].split(/\(\d+\)/)[0].strip!
end

def imdb_rating
  @imdb_page.search('div.ipl-rating-star').search('span').children[3].content.to_f
end

def imdb_votes
  @imdb_page.search('div.allText').children[3].content.delete(',').to_i
end

def color_compare(old, new)
  return new.to_s if old == new
  return new.to_s.light_magenta if old > new

  new.to_s.light_cyan
end

def title_id_badge(title)
  badge = "[#{title['id']}]"
  badge.light_green
end

def title_line(title, update)
  puts "#{title_id_badge(title)} '#{title['title']} (#{title['premiered'][0..3]})' - " \
       "#{title['rating']} ⭐ / #{title['votes']} ✓ #{update}"
end

def title_update(title)
  ">> #{color_compare(title['rating'], imdb_rating)} ⭐︎ / #{color_compare(title['votes'], imdb_votes)} ✓"
end

def title_mismatch_warn(title)
  puts "#{title_id_badge(title)} #{'WARN:'.yellow}"\
       " Title mismatch between '#{title['title']}' (Kodi) and '#{imdb_title}' (IMDB)"
end

def update_database_entry(title)
  mysql_query = "UPDATE movie_view SET rating='#{imdb_rating}', votes='#{imdb_votes}' WHERE idMovie='#{title['id']}';"
  mysql_client = MySQL2Helper.new(@config)
  mysql_client.query(mysql_query)
end

def process_title(title)
  id = title['imdb_id']
  update = '(N/C)'
  link = "http://www.imdb.com/title/#{id}/ratings/?ref_=tt_ov_rt"
  fetch_page(link)
  if (title['rating'] != imdb_rating) || (title['votes'] != imdb_votes)
    update_database_entry(title)
    update = title_update(title)
  end
  title_line(title, update)
  title_mismatch_warn(title) if title['title'] != imdb_title
rescue OpenURI::HTTPError => e
  puts "ERROR: #{e} when trying to read #{link} for '#{title['title']}'"
rescue NoMethodError => e
  puts "ERROR: #{e} when trying to process '#{title['title']}'"
end

def start_scan
  @config = load_configuration

  start = ENV['START'] ? ENV['START'].to_i : 0
  limit = ENV['LIMIT'] ? ENV['LIMIT'].to_i : 20
  mysql_query = 'SELECT idMovie as id, c00 as title, votes, rating, premiered, uniqueid_value as imdb_id' \
                " from movie_view ORDER BY idMovie DESC LIMIT #{start},#{limit};"

  mysql_client = MySQL2Helper.new(@config)
  results = mysql_client.query(mysql_query)

  puts "Checking IMDB ratings for #{results.count} titles in Kodi"

  results.each_slice(@config['max_threads']) do |slice|
    slice.each do |title|
      fork do
        process_title(title)
      end
    end
    Process.waitall
  end
end

start_scan
