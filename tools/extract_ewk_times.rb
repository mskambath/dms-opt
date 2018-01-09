#!/usr/bin/env ruby
require 'csv'
require 'roo'

if not (ARGV.length == 2 or ARGV.length == 3) then
  print "DMS-Aufstellung [Zeitenimport]\n"
  if ARGV.length > 3 then
    print "Too many arguments found!\n"
  end
  if ARGV.length < 2 then
    print "Missing at least one argument!\n"
  end
  print "\nUsage:\nextract_ewk_times.rb <file> <sex> [table]\n"
  print "  file:  A XLSX-file that contains the DMS times.\n"
  print "  sex:   M for male, or F for female.\n"
  print "  table: The table of the XLSX file.\n"
  exit
end


filen  = ARGV[0]
sex    = ARGV[1]
if ARGV.length==3 then
  table  = ARGV[2]
end

xlsx = Roo::Spreadsheet.open(filen)
sheet = xlsx.sheet(0)
row = 0

ltc = {}
ltc_lst = []
swimmer_map = {}
swimmer_lst = []

def is_entry_row(row)
  if row==nil then return false end
  if row.length < 5 then return false end
  if row[2] == nil then return false end
  return row[2].scan(/\d\d\d\d/).length==1 
end

# Pl, Name, Jg.,Zeit,...
while row<=sheet.last_row do
  current_row = sheet.row(row)
  if current_row.length>0 and current_row[0]!= nil then
    r = current_row[0].scan(/\d+m.[SRBFL]/).map{|s| s.tr("m ","")}
    if r.length > 0 then
      ltc_key = r[0]
      if ltc[ltc_key]==nil then
        ltc[ltc_key] = true
        ltc_lst[ltc_lst.length] = ltc_key
      end
      row = row+2
      while  row<=sheet.last_row and is_entry_row(sheet.row(row)) do
        time = sheet.row(row)[3]
        name = sheet.row(row)[1]
        n = name.split(",")
        name = n[1].strip + " " + n[0].strip
        if not swimmer_map[name] then
          swimmer_lst[swimmer_lst.length] = name
          swimmer_map[name] = {}
        end
        swimmer_map[name][ltc_key] = time
        row = row + 1
      end
    else
      row = row+1
    end
  else
    row = row + 1
  end
end

print "Schwimmer,Geschlecht"
for ltc_key in ltc_lst do
  print "," + ltc_key 
end
print "\n"

for swimmer in swimmer_lst do
  print swimmer + ","+ sex
  map = swimmer_map[swimmer]
  for ltc_key in ltc_lst do
    time = map[ltc_key]
    if time == nil then time = "" else time = '"' + time.tr("* ","") + '"' end
    print ","+time
  end
  print "\n"
end

