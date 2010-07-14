#!/usr/bin/env ruby
require 'rubygems'
require 'nokogiri'
require 'Text'

algorithms = {}

algorithms['Naive'] = Proc.new do |fileName|
  fileName
end

algorithms['RemoveExtension'] = Proc.new do |fileName|
  fileNameWithoutExtension = /^(.*)\.([a-z]){2,4}$/i.match(fileName)[1]
  fileNameWithoutExtension
end


def rankDifference(originalString, givenString)
  return 100.0 * Text::Levenshtein.distance(originalString, givenString).to_f/([originalString.length, givenString.length].max.to_f)
end

doc = Nokogiri::HTML(open('MovieLibrary.html'))
algorithms.each_key do |cleaner_proc_name|
  cleaner_proc = algorithms[cleaner_proc_name]
  totalScore = 0.0
  doc.css('#movie_file_names tr').each do |movie|
    original_file_node = movie.css('td:first-child').first
    expected_movie_node =  movie.css('td:nth-child(2)').first
    if (original_file_node != nil && expected_movie_node != nil)
      score = rankDifference(cleaner_proc.call(original_file_node.content), expected_movie_node.content)
      totalScore += score
      puts "#{score} : #{original_file_node.content.inspect} : Got #{cleaner_proc.call(original_file_node.content).inspect}, expected #{expected_movie_node.content.inspect}" if ARGV.member?('v')
    end
  end
  puts "-----------------" if ARGV.member?('v')
  puts "TOTAL SCORE for #{cleaner_proc_name.inspect} : (lower is better): #{totalScore.round}"
  puts " " if ARGV.member?('v')
  puts " " if ARGV.member?('v')
end