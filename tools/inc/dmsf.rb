CONFIG_FILE="dms.cfg"

def normalizeTimeString(timestr)
  if timestr == nil then
    return "00:00:00,00"
  end
  return case timestr.length
         when 11 then ""
         when 10 then "0"
         when 9 then "00"
         when 8 then "00:"
         when 7 then "00:0"
         when 6 then "00:00"
         when 5 then "00:00:"
         when 4 then "00:00:0"
         when 3 then "00:00:00"
         when 2 then "00:00:00,"
         when 2 then "00:00:00,0"
         when 0 then "00:00:00,00"  
         end + timestr        
end

def normalizedTimeString(time)
  total_seconds = time

  seconds = total_seconds % 60
  total_minutes = seconds / 60
  minutes = total_minutes % 60
  total_hours   = total_minutes % 60
  return (total_hours.to_s + ":" + minutes.to_s + ":" + seconds.to_s).tr(".",",")
end

def translateStyle(style)
  return case style
         when "FREE"
           "F"
         when "BACK"
           "R"
         when "BREAST"
           "B"
         when "FLY"
           "S"
         when "MEDLEY"
           "L"
         end
end

def smallRomanNum(num)
  case num
  when 1..3
    return "I"*num
  when 4
    return "IV"
  when 5..8
    return "V" + ("I"*(num-5))
  else
    return "I"*(10-num) + "X"
  end
end

#
#
# param config_file: A file describing a full DMS session,
#                    which includes all events and their duration.
#                    Each line in such file is of the form:
#                    <LengthSwimTypeCombination>,<Sex>,<Duration>
# return:            An array that contains for each event of a session
#                    a subarray containing the same entries as in the
#                    file, and the begin and end times computed by the
#                    given durations.
def read_dms_config(config_file)
  dms = []  
  idx = 0
  CSV.foreach("dms.cfg") do |row|
    key        = row[0].tr(" ","")
    sex        = row[1]
    duration   = row[2].to_f
    begin_time = if idx==0 then 0 else dms[idx-1][4] end
    end_time   = begin_time + duration  
    dms[idx]   = [key,sex,duration,begin_time,end_time]
    idx = idx + 1
  end

  return dms
end

# 
# return: A list and a hashmap that include all events of a session
#         of a given DMS for a specific sex. The hashmap just maps the
#         length-swimtype-combination to the related event
#         if it exists in the list.
def extract_ltcs(dms, sex)
  filtered_dms = dms.select{|event| event[1]==sex}
  filtered_dms_list = filtered_dms.map{|event| event}
  filtered_dms_hash = filtered_dms.map{|event| [event[0],event]}.to_h
  return filtered_dms_list, filtered_dms_hash
end
