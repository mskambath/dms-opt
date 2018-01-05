#!/usr/bin/env ruby
require 'csv'

if not ARGV.length == 2 then
  print "DMS-Aufstellung [Schwimmerliste]\n"
  if ARGV.length > 2 then
    print "Too many arguments found!\n"
  end
  if ARGV.length < 2 then
    print "Missing at least one argument!\n"
  end
  print "\nUsage:\nextract_points_table.rb <file> <gender>\n"
  print "  file:    A CSV-file that contains all available swimmer, their sex,\n"
  print "           and their times.\n"
  print "  gender:  M for male, or F for female, X for mixed\n"
  exit
end

gender = ARGV[1]
skipped_first=false
CSV.foreach(ARGV[0]) do |row|
  if not skipped_first then
    skipped_first = true
  elsif row[1]==gender or gender=="X" then 
    print row[0]+"\n"
  end
end

