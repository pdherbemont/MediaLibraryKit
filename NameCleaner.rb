#!/usr/bin/env ruby
require 'rubygems'
require 'nokogiri'
require 'Text'

def cleanName(originalFileName)
  fileNameWithoutExtension = /^(.*)\.([a-z]){2,4}$/i.match(originalFileName)[1]
  return fileNameWithoutExtension
end

def rankDifference(originalString, givenString)
  return 100.0 * Text::Levenshtein.distance(originalString, givenString).to_f/([originalString.length, givenString.length].max.to_f)
end

doc = Nokogiri::HTML(open('MovieLibrary.html'))
totalScore = 0.0
doc.css('#movie_file_names tr').each do |movie|
  original_file_node = movie.css('td:first-child').first
  expected_movie_node =  movie.css('td:nth-child(2)').first
  if (original_file_node != nil && expected_movie_node != nil)
    score = rankDifference(cleanName(original_file_node.content), expected_movie_node.content)
    totalScore += score
    puts "#{score} : #{original_file_node.content.inspect} : Got #{cleanName(original_file_node.content).inspect}, expected #{expected_movie_node.content.inspect}"
  end
end
puts "-----------------"
puts "TOTAL SCORE (lower is better): #{totalScore.round}"
