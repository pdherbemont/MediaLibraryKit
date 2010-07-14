#!/usr/bin/env ruby
require 'rubygems'
require 'nokogiri'
require 'Text'

$building_blocks = {}

$building_blocks['NoExt'] = Proc.new do |fileName|
  (/^(.*)\.([a-z]){2,4}$/i.match(fileName)||['', fileName])[1]
end

$building_blocks['NoExt2'] = Proc.new do |fileName|
  (/^(.*)\.([a-z]){2,4}$/i.match(fileName)||['', fileName])[1]
end

$building_blocks['NoExt3'] = Proc.new do |fileName|
  (/^(.*)\.([a-z]){2,4}$/i.match(fileName)||['', fileName])[1]
end



$algorithms = []

def combine_building_blocks(available_block_names, current_block_stack)
  $algorithms << current_block_stack
  available_block_names.each do |block|
    combine_building_blocks(available_block_names.reject{|block_name| block_name == block}, current_block_stack + [block])
  end
end

combine_building_blocks($building_blocks.keys, [])

# algorithms['Naive'] = Proc.new do |fileName|
#   fileName
# end
# 
# algorithms['RemoveExtension'] = Proc.new do |fileName|
#   fileNameWithoutExtension = /^(.*)\.([a-z]){2,4}$/i.match(fileName)[1]
#   fileNameWithoutExtension
# end
# 
# 
# algorithms['RemoveExtensionAndRenameDots'] = Proc.new do |fileName|
#   fileNameWithoutExtension = /^(.*)\.([a-z]){2,4}$/i.match(fileName)[1]
#   dots_removed = fileNameWithoutExtension.gsub('.', ' ')
#   everything_before_bad_keyword = (/^(.*)(FRENCH|DVDRIP|XVID|DIVX)(.*)$/i.match(dots_removed) || ['', dots_removed])[1]
#   everything_before_bad_keyword
# end
# 
# algorithms['R3'] = Proc.new do |fileName|
#   fileNameWithoutExtension = /^(.*)\.([a-z]){2,4}$/i.match(fileName)[1]
#   dots_removed = fileNameWithoutExtension.gsub('.', ' ')
#   everything_before_bad_keyword_case_sensitive = (/^(.*)(FRENCH)(.*)$/.match(dots_removed) || ['', dots_removed])[1]
#   everything_before_bad_keyword = (/^(.*)(TRUEFRENCH|DVDRIP|XVID|DIVX)(.*)$/i.match(everything_before_bad_keyword_case_sensitive) || ['', everything_before_bad_keyword_case_sensitive])[1]
#   everything_before_bad_keyword
# end
# 
# algorithms['R3'] = Proc.new do |fileName|
#   fileNameWithoutExtension = /^(.*)\.([a-z]){2,4}$/i.match(fileName)[1]
#   dots_removed = fileNameWithoutExtension.gsub('.', ' ')
#   everything_before_bad_keyword_case_sensitive = (/^(.*)(FRENCH)(.*)$/.match(dots_removed) || ['', dots_removed])[1]
#   everything_before_bad_keyword = (/^(.*)(TRUEFRENCH|DVDRIP|XVID|DIVX)(.*)$/i.match(everything_before_bad_keyword_case_sensitive) || ['', everything_before_bad_keyword_case_sensitive])[1]
#   everything_before_bad_keyword
# end
# 
# algorithms['R4'] = Proc.new do |fileName|
#   fileNameWithoutExtension = /^(.*)\.([a-z]){2,4}$/i.match(fileName)[1]
#   dots_removed = fileNameWithoutExtension.gsub('.', ' ')
#   everything_before_bad_keyword_case_sensitive = (/^(.*)(FRENCH)(.*)$/.match(dots_removed) || ['', dots_removed])[1]
#   everything_before_bad_keyword = (/^(.*)(TRUEFRENCH|DVDRIP|XVID|DIVX)(.*)$/i.match(everything_before_bad_keyword_case_sensitive) || ['', everything_before_bad_keyword_case_sensitive])[1]
#   remove_between_parenthesis = everything_before_bad_keyword.gsub(/\(.*\)/, '')
#   remove_between_parenthesis
# end
# 




# ---------------- DO NOT MODIFY BELOW HERE -------------


def rankDifference(originalString, givenString)
  return 100.0 * Text::Levenshtein.distance(originalString, givenString).to_f/([originalString.length, givenString.length].max.to_f)
end

doc = Nokogiri::HTML(open('MovieLibrary.html'))
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
  puts "TOTAL SCORE for #{algorithm.inspect} : (lower is better): #{totalScore.round}"
  puts " " if ARGV.member?('v')
  puts " " if ARGV.member?('v')
end