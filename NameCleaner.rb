#!/usr/bin/env ruby
require 'rubygems'
require 'nokogiri'
require 'Text'

$building_blocks = {}

$building_blocks['NoExt'] = Proc.new do |fileName|
  (/^(.*)\.([a-z]){2,4}$/i.match(fileName)||['',fileName])[1]
end

$building_blocks['DotsBecomeSpaces'] = Proc.new do |fileName|
  fileName.gsub('.',' ')
end

$building_blocks['DeleteAfterKeyword'] = Proc.new do |fileName|
  (/^(.*)(TRUEFRENCH|DVDRIP|XVID|DIVX)(.*)$/i.match(fileName) || ['',fileName])[1]
end

$building_blocks['DeleteAfterCaseSensitiveKeyword'] = Proc.new do |fileName|
  (/^(.*)(FRENCH)(.*)$/.match(fileName) || ['',fileName])[1]
end

$building_blocks['DeleteBetweenParenthesis'] = Proc.new do |fileName|
  fileName.gsub(/\(.*\)/, '')
end

$building_blocks['CollapseWhitespaces'] = Proc.new do |fileName|
  fileName.gsub(/\s+/, ' ')
end

$building_blocks['RemoveYears'] = Proc.new do |fileName|
  fileName.gsub(/(19|20)\d\d/, '')
end

$building_blocks['UnderscoresBecomeSpaces'] = Proc.new do |fileName|
  fileName.gsub('_', ' ')
end

$building_blocks['StripWhitespaces'] = Proc.new do |fileName|
  fileName.strop
end

$building_blocks['Capitalize'] = Proc.new do |fileName|
  fileName.capitalize
end

# ---------------- DO NOT MODIFY BELOW HERE -------------

$algorithms = []

def combine_building_blocks(available_block_names, current_block_stack)
  $algorithms << current_block_stack
  available_block_names.each do |block|
    combine_building_blocks(available_block_names.reject{|block_name| block_name == block}, current_block_stack + [block])
  end
end

combine_building_blocks($building_blocks.keys, [])

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