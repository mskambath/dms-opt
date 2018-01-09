#!/usr/bin/env ruby
require 'csv'
require_relative 'inc/dmsf'

### Argument Checking:
if not (ARGV.length == 1 or ARGV.length==2) then
  print "DMS-Aufstellung [Zeiterfassung]\n"
  if ARGV.length > 2 then
    print "Too many arguments found!\n"
  end
  if ARGV.length < 1 then
    print "Missing at least one argument!\n"
  end
  print "\nUsage:\ncreate_dms_gmpltimetable <team> [timef]\n"
  print "  team:   The name of the team\n"
  print "  timef:  A CSV-file containing all times for all swimmers.\n"
  print "          If undefined 'dms-times.csv' will be used."
  exit
end

team_name = ARGV[0]

timef = "dms-times.csv"
if ARGV.length==2 then
  timef = ARGV[1]
end

inteam = {}


teamf   = "teams/" + team_name + "/team"
genderf = "teams/" + team_name + "/gender"
gender  = ""
File.readlines(teamf).each{|line|  inteam[line.chomp] = true}
File.readlines(genderf).each{|line| gender = line.chomp}

dms = read_dms_config(CONFIG_FILE)
dms_strecken,dms_instrecken = extract_ltcs(dms, gender)


print "data;\n"
print "param bestzeit:"

idx    = 0

ltc = []
covered = {}
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
      time    = row[i]
      if dms_instrecken[ltc_key] then
        print "\t" +'"' +  normalizeTimeString(time) + '"'
      end
    end
    covered[row[0]] = true
    print "\n"
  end
  
  idx = idx + 1
end


print ";\n\n"
print "end;\n"
