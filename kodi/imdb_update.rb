#!/usr/bin/env ruby
# frozen_string_literal: true

require 'colorize'
require 'nokogiri'
require 'open-uri'
require_relative 'helpers/mysql2'

def fetch_page(link)
  @imdb_page = Nokogiri::HTML(URI.parse(link).open)
rescue OpenURI::HTTPError => e
  puts "ERROR: #{e} - #{link}"
  abort
end

def imdb_title
  @imdb_page.at("//head/meta[@name='title']")['content'].split(/\(\d+\)/)[0].strip!
end

def imdb_rating
  @imdb_page.search('div.ratingValue').search('span').children[0].content.to_f
end

def imdb_votes
  @imdb_page.search('div.imdbRating').search('a').children[0].content.delete(',').to_i
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
  puts title_id_badge(title) + ' ' + 'WARN:'.yellow +
       " Title mismatch between '#{title['title']}' (Kodi) and '#{imdb_title}' (IMDB)"
end

def process_title(title)
  id = title['imdb_id']
  update = '(N/C)'
  fetch_page("http://www.imdb.com/title/#{id}")

  if (title['rating'] != imdb_rating) || (title['votes'] != imdb_votes)
    mysql_query = "UPDATE movie_view SET rating='#{imdb_rating}', votes='#{imdb_votes}' WHERE idMovie='#{title['id']}';"
    mysql_client = MySQL2Helper.new(MYSQL_CONFIG)
    mysql_client.query(mysql_query)
    update = title_update(title)
  end
  title_line(title, update)
  title_mismatch_warn(title) if title['title'] != imdb_title
end

MAX_THREADS = 100
MYSQL_CONFIG = {
  host: '192.168.2.2',
  username: 'kodi',
  password: 'kodi',
  database: 'MyVideos116'
}.freeze

start = ENV['START'] ? ENV['START'].to_i : 0
limit = ENV['LIMIT'] ? ENV['LIMIT'].to_i : 20
mysql_query = 'SELECT idMovie as id, c00 as title, votes, rating, premiered, uniqueid_value as imdb_id' \
              " from movie_view ORDER BY idMovie DESC LIMIT #{start},#{limit};"

mysql_client = MySQL2Helper.new(MYSQL_CONFIG)
results = mysql_client.query(mysql_query)

puts "Checking IMDB ratings for #{results.count} titles in Kodi"

results.each_slice(MAX_THREADS) do |slice|
  slice.each do |title|
    fork do
      process_title(title)
    end
  end
  Process.waitall
end
