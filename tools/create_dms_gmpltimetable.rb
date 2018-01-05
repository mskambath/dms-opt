#!/usr/bin/env ruby
require 'csv'
require_relative 'inc/dmsf'

### Argument Checking:
if not ARGV.length == 1 then
  print "DMS-Aufstellung [Zeiterfassung]\n"
  if ARGV.length > 1 then
    print "Too many arguments found!\n"
  end
  if ARGV.length < 1 then
    print "Missing at least one argument!\n"
  end
  print "\nUsage:\ncreate_dms_gmpltimetable <team>\n"
  print "  team:  The name of the team\n"
  exit
end



inteam = {}


teamf   = "teams/" + ARGV[0] + "/team"
genderf = "teams/" + ARGV[0] + "/gender"
gender  = ""
File.readlines(teamf).each{|line|  inteam[line.chomp] = true}
File.readlines(genderf).each{|line| gender = line.chomp}

dms = read_dms_config(CONFIG_FILE)
dms_strecken,dms_instrecken = extract_ltcs(dms, gender)

timef = "dms-times.csv"

print "data;\n"
print "param bestzeit:"

idx    = 0

ltc = []
CSV.foreach(timef) do |row|
  if idx == 0 then
    # col-0 contains the name
    # col-1 contains the gender
    for i in 2...row.length do
      ltc_key = row[i]
      ltc[i-2] = ltc_key
      if dms_instrecken[ltc_key] then
        print "\t" + ltc_key
      end
    end
    print "\t:= \n"
  elsif inteam[row[0]] then
    print '"' + row[0] + '"'
    for i in 2...row.length do
      ltc_key = ltc[i-2]
      #print row[0]+" "+ltc_key +"\t"
      time = row[i]
      if dms_instrecken[ltc_key] then
        print "\t" +'"' +  normalizeTimeString(time) + '"'
        #print normalizeTimeString(row[i])
      end
      #print "\n"
    end
    print "\n"
  end
  
  idx = idx + 1
end


print ";\n\n"
print "end;\n"
