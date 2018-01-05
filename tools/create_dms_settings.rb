#!/usr/bin/env ruby
require 'csv'
require_relative 'inc/dmsf'

if not ARGV.length == 2 then
  print "DMS-Aufstellung [Zeiterfassung]\n"
  if ARGV.length > 2 then
    print "Too many arguments found!\n"
  end
  if ARGV.length < 2 then
    print "Missing at least one argument!\n"
  end
  print "\nUsage:\ncreate_dms_settings <gender> <sessions>\n"
  print "  gender:    M for male, or F for female\n"
  print "  sessions:  A number between 1 to 3\n" 
  exit
end

gender   = ARGV[0]
sessions = ARGV[1].to_i

#
# Einlesen des Aufbaus eines DMS-Abschnittes
#
dms = read_dms_config(CONFIG_FILE)
dms_strecken,dms_instrecken = extract_ltcs(dms, gender)
anf_zeit=dms_strecken.map{|x| x[3]}
end_zeit=dms_strecken.map{|x| x[4]}

print "data;\n"
print "set Abschnitte := \n   "
for abs in 1..sessions do
  print " " + smallRomanNum(abs)
end
print ";\n/* Alle Abschnitte des Wettkampfes */\n\n"

print "set Strecken   := \n  "
dms_strecken.each{|event| print " " + event[0]}
print ";\n/* Alle je Abschnitt zu belegenden Strecken */\n\n"


print "param anf_zeit := \n  "
dms_strecken.each{|event| print "\n"+event[0]+"  "+event[3].to_s}
print ";\n\n"


print "param end_zeit := \n  "
dms_strecken.each{|event| print "\n"+event[0]+"  "+event[4].to_s}
print ";\n\n"

print "end;\n"
