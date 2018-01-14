#!/usr/bin/env ruby
# coding: utf-8
require 'csv'
require_relative 'inc/dmsf'

if not ARGV.length == 2 then
  print "DMS-Aufstellung [Bedingungen]\n"
  if ARGV.length > 2 then
    print "Too many arguments found!\n"
  end
  if ARGV.length < 2 then
    print "Missing at least one argument!\n"
  end
  print "\nUsage:\ncreate_dms_constraints <sessions> <team>\n"
  print "  sessions:  A number between 1 to 3\n"
  print "  team:      The name of the team.\n"
  exit
end

sessions = ARGV[0].to_i
team     = ARGV[1]

max_starts_in_total    = 4
max_starts_per_session = 4
min_starts_in_total    = 0
min_pause              = 5

swimmer=[]
File.readlines("teams/"+team+"/team").each{|s|
  swimmer[swimmer.length] = s.chomp
}

print "data;\n"

print "set Schwimmer := \n  "
swimmer.each{|s| print ' "' + s +  '"'}
print ";\n"
print "/* Alle zur Verfügung stehenden Schwimmer */\n\n"

print "set feste_strecken := ;\n"
print '/* gibt eine festen Strecke für einen Schwimmer vor z.B.: ("Martin Mustermann",200R) */'
print "\n\n"

print "set block_strecken := ;\n"
print '/* Verbietet bestimmte Strecke für einen Schwimmer z.B.: ("Martin Mustermann",50B) */'
print "\n\n"

print "set feste_starts := ;\n"
print '/* gibt einen Start fest vor z.B.: ("Martin Mustermann",200R,I) */'
print "\n\n"

print "set block_starts := ;\n"
print '/* Verbiete einen bestimmten Start eines Schwimmers z.B.: ("Martin Mustermann",1500F,I) */'
print "\n\n"

print "set block_strpaare   := ;\n"
print "/* blockiert 2 Strecken innerhalb eines Abschnittes für alle Schwimmer z.B.: (1500F,100S) */\n\n"

print "set block_swimmer_strpaare := ;\n"
print '/* blockiert 2 Strecken innerhalb eines Abschnittes für einen Schwimmer z.B.: ("Martin Mustermann",400F,200S) */'
print "\n\n"

print "set block_wkpaare    := ;\n"
print "/* blockiert 2 Wettkämpfe (abschnittsübergreifend) für jeden Schwimmer z.B.: (1500F,I,100S,I) */\n\n"


######################
print "param max_st := "
swimmer.each{|s|
  print "\n"
  print ' "' + ("%-15s" % (s +  '"'))
  print "\t" +  max_starts_in_total.to_s 
}
print ";\n/* Anzahl (alle Abschnitte) an Starts fuer jeden Schwimmer beschränken. */\n\n"

######################
print "param max_abs_st: "
(1..sessions).each{|session|  print " " + smallRomanNum(session)}

print ":="
swimmer.each{  |sw|
  print "\n"
  print ' "' + ("%-15s" % (sw +  '"')) + "\t"
  (1..sessions).each{|session| print " " + max_starts_per_session.to_s}
}
print ";\n"
print "/* Anzahl an Starts (je Abschnitt) fuer jeden Schwimmer beschränken. */\n\n"

######################
print "param min_st :="
swimmer.each{|s|
  print "\n"
  print ' "' + ("%-15s" % (s +  '"')) +"\t" +  + min_starts_in_total.to_s 
}
print ";\n"
print "/* Mindestanzahl an Starts je Schwimmer. */\n\n"

######################
print "param min_pause :="
swimmer.each{|s|
  print "\n"
  print ' "' + ("%-15s" % (s +  '"'))  + "\t"  +min_pause.to_s 
}
print ";\n"
print "/* Mindestpause je Schwimmer. */\n\n"

print "end;\n"
