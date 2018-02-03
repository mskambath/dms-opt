# DMS-AUFSTELLUNGSBERECHNUNG
#   Malte Skambath, 2016-2017
#
# Usage: 
#       glpsol -m dms.mod -d dms-setting.dat -d dms-points.dat -d dms-data.dat
										

/** Wettkampfbeschreibung **/
/* alle verfügbaren Schwimmstrecken */
set Strecken;    

/* alle Abschnitte */
set Abschnitte;

/* alle Wettkämpfe */
set WK := Strecken cross Abschnitte;

/* Anfangs- und Endzeit einer Strecke, relativ zum Abschnittsbeginn */
param anf_zeit{st in Strecken}, >=0;
param end_zeit{st in Strecken}, >=0;
param pausenzeit{st1 in Strecken, st2 in Strecken} 
      := if anf_zeit[st2]-end_zeit[st1] < 0 then  
           anf_zeit[st1]-end_zeit[st2] 
         else 
           anf_zeit[st2]-end_zeit[st1] ;


/** Beschreibung der Aufstellungsbedingungen **/
/* die teilnehmenden Schwimmer */
set Schwimmer;   

/* alle möglichen Starts */
set Starts       := Schwimmer cross WK; 
set Startpaar    := Schwimmer cross WK cross WK;
set Streckenpaar := Strecken cross Strecken;

/* Vorgegebene und blockierte Starts */
set feste_starts  within Starts;
set block_starts  within Starts;
set block_wkpaare within WK cross WK;
set block_strpaare within Strecken cross Strecken;
set block_swimmer_strpaare within Schwimmer cross Streckenpaar;

/* Vorgegebene und blockierte Strecken */
set feste_strecken within Schwimmer cross Strecken;
set block_strecken within Schwimmer cross Strecken;



param min_pause{sw in Schwimmer}, >=0;

/* Zeiten für die Punktetabelle */
param basiszeit{st in Strecken},symbolic;
param basiszeit_s{st in Strecken}
      := str2time(basiszeit[st], "%H:%M:%S")+substr(basiszeit[st],10,2)/100;
   

/* Bestzeiten je Schwimmer und Strecke */
param bestzeit{sw in Schwimmer,st in Strecken},symbolic;
param bestzeit_s{sw in Schwimmer,st in Strecken},>=0
      := str2time(bestzeit[sw,st], "%H:%M:%S")+substr(bestzeit[sw,st],10,2)/100;

/* Punkte von Schwimmer sw auf Schwimmstrecke st */
#param p{sw in Schwimmer,st in Strecken}, >=0, <=1000; 
param p{sw in Schwimmer, st in Strecken} 
      := if bestzeit_s[sw,st] == 0 then  
           0
         else 
           floor(1000 * (basiszeit_s[st]/bestzeit_s[sw,st])**3) ;

#printf{sw in Schwimmer, st in Strecken} '%s %s %s\n',sw,st,p[sw,st];

/* Maximale Anzahl an Starts je Schwimmer */
param max_st{sw in Schwimmer}, >=0, integer;

/* Minimale Anzahl an Starts je Schwimmer */
param min_st{sw in Schwimmer}, >=0 integer;

/* Maximale Anzahl an Starts pro Abschnitt je Schwimmer */
param max_abs_st{sw in Schwimmer, abs in Abschnitte}, >=0, integer;


var x{(sw, st, abs) in Starts} >= 0, binary;
/* Belegung der Schwimmstrecken */

maximize points:
    sum{(sw, st, abs) in Starts}
    p[sw,st]*  x[sw,st,abs];
    /* Summe aller Punkte geschwommener Strecken */

# Bedingungen für einen korrekten Wettkampf:

s.t. belegung_st{st in Strecken, sw in Schwimmer}: 
     sum{abs in Abschnitte} x[sw,st,abs] <= 1; 
/* Keine doppelte Streckenbelegung mit dem selben Schwimmer */

s.t. belegung_wk{(st, abs) in WK}: 
     sum{sw in Schwimmer} x[sw,st,abs] <= 1; 
/* Keine doppelte Belegung eines Wettkampfes */

# Bedingungen der DMS:

s.t. auslastung_max{sw in Schwimmer}:
     sum{st in Strecken, abs in Abschnitte} x[sw,st,abs] <= max_st[sw];
/* Beachte die minimale Anzahl an Starts pro Schwimmer */

s.t. auslastung_min{sw in Schwimmer}:
     sum{st in Strecken, abs in Abschnitte} x[sw,st,abs] >= min_st[sw];
/* Beachte die maximale Anzahl an Starts pro Schwimmer */

# Weitere Anforderungen:

s.t. auslastung_abs{sw in Schwimmer, abs in Abschnitte}:
    sum{st in Strecken} x[sw,st,abs] <= max_abs_st[sw,abs];
/* Beachte die Auslastung eines Schwimmers pro Abschnitt */

s.t. pause_allg{
         abs in Abschnitte,
         st1 in Strecken,
         st2 in Strecken, 
         sw in Schwimmer: 
         pausenzeit[st1,st2]< min_pause[sw] and st1<>st2}:
     x[sw,st1,abs]+x[sw,st2,abs] <= 1; 
/* Die allgemeinen Pausenzeiten jedes Schwimmers müssen eingehalten werden*/

s.t. start_vorgabe{ (sw,st,abs) in feste_starts}:  x[sw,st,abs] = 1;
s.t. start_blockade{(sw,st,abs) in block_starts}:  x[sw,st,abs] = 0;
s.t. strecken_vorgabe{(sw,st) in feste_strecken}:
     sum{abs in Abschnitte} x[sw,st,abs] = 1;
s.t. strecken_blockade{(sw,st) in block_strecken}:
    sum{abs in Abschnitte} x[sw,st,abs] = 0;
s.t. wkpaar_blockade{(st1,abs1,st2,abs2) in block_wkpaare, sw in Schwimmer}:
    x[sw,st1,abs1] + x[sw,st2,abs2] <= 1;
s.t. stpaar_abs_blockade{
        abs in Abschnitte,
        (st1,st2) in block_strpaare,
        sw in Schwimmer}:
    x[sw,st1,abs] + x[sw,st2,abs] <= 1;
s.t. stpaar_abs_blockade_sw{
        abs in Abschnitte,
	(sw,st1,st2) in block_swimmer_strpaare}:
    x[sw,st1,abs] + x[sw,st2,abs] <= 1;

/* Vorgaben und Blockaden */

solve;

# Ergebnisse
printf '\n\n#################################\n\n';
printf 'DMS-Aufstellung / ILP Model Ergebnis\n';
printf '\n';
#printf 'Maximale Punkte = %s\n', points;
printf 'Gesamtaufstellung (%s Punkte):\n', points;
printf '\n';


#printf{st in Strecken, abs in Abschnitte, sw in Schwimmer}:'%14s %10s %11s %12s\n',sw,st,abs, x[sw,st,abs]; 




#printf 'Gesamtaufstellung:\n';
for {abs in Abschnitte} {
  printf '\nAbschnitt %3s (%0.0f Punkte)\n', 
         abs, sum{sw in Schwimmer, st in Strecken} x[sw,st,abs] * p[sw,st];
  printf '------------------------------\n';
  for {st in Strecken} {
    printf '%6s',st;
    for {sw in Schwimmer} {

      printf "" & (if (x[sw,st,abs]==1) then " %-17s %5s (%s)" else ""),sw,p[sw,st],bestzeit[sw,st];
      printf "" & (if (card({ stx in Strecken : anf_zeit[st] >= end_zeit[stx] and x[sw,st,abs]==1 and x[sw,stx,abs]==1})>0) then " P: %2.f" else "") , 
      ceil(min{ stx in Strecken : anf_zeit[st] >= end_zeit[stx] and x[sw,st,abs]==1 and x[sw,stx,abs]==1} pausenzeit[stx,st]);
    }
    printf '\n';
  }
}

printf '\n\nSchwimmerübersicht:\n';
printf '-----------------------\n';
for {sw in Schwimmer} {
    printf '%-17s:\t',sw;
    for{abs in Abschnitte,st in Strecken  : x[sw,st,abs]==1} {
        printf '  %5s %2s',st,abs;
    }
    printf '\n';
}
printf '\n';

end;
#printf{st1 in Strecken, st2 in Strecken} "%5s %5s %5s\n",st1,st2,time[st1,st2]; 
