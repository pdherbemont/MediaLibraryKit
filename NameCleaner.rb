#!/usr/bin/env ruby
require 'rubygems'
require 'nokogiri'
require 'Text'
require 'open-uri'
require 'json'

$building_blocks = {}

$building_blocks['NoExt'] = Proc.new do |fileName|
  (/^(.*)\.([a-z]){2,4}$/i.match(fileName)||['',fileName])[1]
end

$building_blocks['DotsAndUnderscoresBecomeSpaces'] = Proc.new do |fileName|
  fileName.gsub(/\.|_/,' ')
end

$building_blocks['DeleteAfterKeyword'] = Proc.new do |fileName|
  match = /(TRUEFRENCH|DVDRIP|XVID|DIVX|BDRIP|REPACK|RIPPDVD)/i.match(fileName) # Case-insensitive
  ifFileName = match ? fileName[0...match.begin(0)] : fileName
  match_sensitive = /(FRENCH|((19|20)\d\d))/.match(ifFileName) # Case-sensitive
  match_sensitive ? ifFileName[0...match_sensitive.begin(0)] : ifFileName
end

$building_blocks['DeleteBetweenParenthesis'] = Proc.new do |fileName|
  fileName.gsub(/\(.*\)/, '')
end

$building_blocks['CapitalizeThenCollapseAndStripWhitespaces'] = Proc.new do |fileName|
  fileName.capitalize.gsub(/\s+/, ' ').strip
end

# ---------------- DO NOT MODIFY BELOW HERE -------------

$algorithms = []

def combine_building_blocks(available_block_names, current_block_stack)
  $algorithms << current_block_stack
  available_block_names.each do |block|
    combine_building_blocks(available_block_names.reject{|block_name| block_name == block}, current_block_stack + [block])
  end
end

puts "Building algorithms..." if ARGV.member?('v')
combine_building_blocks($building_blocks.keys, [])
puts "Done !" if ARGV.member?('v')

def rankDifference(originalString, givenString)
  # return 100.0 * Text::Levenshtein.distance(originalString, givenString).to_f/([originalString.length, givenString.length].max.to_f)
  return Text::Levenshtein.distance(originalString, givenString)
end

doc = Nokogiri::HTML(open('MovieLibrary.html'))
results = {}

$algorithms.each do |algorithm|
  totalScore = 0.0
  doc.css('#movie_file_names tr').each do |movie|
    original_file_node = movie.css('td:first-child').first
    expected_movie_node =  movie.css('td:nth-child(2)').first
    if (original_file_node != nil && expected_movie_node != nil)
      original_file_name = original_file_node.content
      expected_movie_name = expected_movie_node.content
      computed_movie_name = original_file_name
      algorithm.each do |block_name|
        computed_movie_name = $building_blocks[block_name].call(computed_movie_name)
      end
      score = rankDifference(computed_movie_name, expected_movie_name)
      totalScore += score
      puts "#{score} : #{original_file_node.content.inspect} : Got #{computed_movie_name.inspect}, expected #{expected_movie_node.content.inspect}" if ARGV.member?('v')
    end
  end
  puts "-----------------" if ARGV.member?('v')
  puts "TOTAL SCORE for #{algorithm.inspect} : (lower is better): #{totalScore.round}" if ARGV.member?('v')
  results[algorithm] = totalScore
  puts " " if ARGV.member?('v')
  puts " " if ARGV.member?('v')
end
results.sort{|a,b| a[1]<=>b[1]}.each do |algo, score|
  puts "#{score.round} for #{algo.inspect}"
end

best_algorithm = results.sort{|a,b| a[1]<=>b[1]}.first[0]
matches = 0
non_matches = 0
doc.css('#movie_file_names tr').each do |movie|
  original_file_node = movie.css('td:first-child').first
  if (original_file_node != nil)
    original_file_name = original_file_node.content
    computed_movie_name = original_file_name
    best_algorithm.each do |block_name|
      computed_movie_name = $building_blocks[block_name].call(computed_movie_name)
    end
    url = URI.escape("http://api.allocine.fr/xml/search?q=#{computed_movie_name}&json=1&partner=1")
    open(url) do |f|
      begin
        puts "#{computed_movie_name.inspect} is in reality #{JSON.parse(f.read)['feed']['movie'][0]['originalTitle'].inspect}"
        matches += 1
      rescue
        puts "Noting in the JSON for #{computed_movie_name.inspect} (Loaded at #{url.inspect})"
        non_matches += 1
      end
    end
  end
end
puts "In the end Allocine found #{matches}, and couldn't find #{non_matches} movies"
