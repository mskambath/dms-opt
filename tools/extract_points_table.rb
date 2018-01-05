#!/usr/bin/env ruby
require 'csv'

if not ARGV.length == 4 then
  print "DMS-Aufstellung [Basiszeiten]\n"
  if ARGV.length > 4 then
    print "Too many arguments found!\n"
  end
  if ARGV.length < 4 then
    print "Missing at least one argument!\n"
  end
  print "\nUsage:\nextract_points_table.rb <file> <year> <cm> <gender>\n"
  print "  file:      A CSV-file that contains the FINA record table.\n"
  print "  year:      The year.\n"
  print "  cm:        SCM* | LCM\n"
  print "  gender:    M for male, or F for female\n"
  exit
end



def createFilter(filename, gender)
  filter = {}
  CSV.foreach(filename) do |row|
    if row[1]==gender then
      filter[row[0].tr(" ","")] = true
    end
  end
  return filter 
end


filen  = ARGV[0]
year   = ARGV[1]
cm     = ARGV[2]
gender = ARGV[3]

no_filter = false
filter = createFilter(CONFIG_FILE,gender)

print "data;\n"
print "param basiszeit := \n"
CSV.foreach(filen) do |row|
  if row[0]==year and row[1] == cm and row[2]==gender then 
    style= row[5]
    distance = row[4]
    timestr = row[6]
    count = row[3]
    key = distance + translateStyle(style)

    if count.to_i == 1 and  filter[key] then
      print key,"\t \"", normalizeTimeString(timestr).tr(".",","),"\"\n"
    end
    
  end
end
print ";\n"
print "end;\n"
