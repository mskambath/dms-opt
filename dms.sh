#!/bin/bash
kw_new="new"
k_male="M"
BACKTITLE="DMS-Aufstellung"
if [ -z "$1" ]; then
    echo $0" <command> args"
    echo ""
    echo "* Commands"
    echo $0" new [<team> [<sex> [<times>]]]"
    echo "    Configurate a new team."
    echo $0" list"
    echo "    List all available teams."
    echo $0" delete  <team>"
    echo "    Deletes a team. This cannot be undone!"
    echo $0" compute <team> [<times>]"
    echo "    Compute a DMS-Assignment."
    echo $0" show <team>"
    echo "   Show the members and basic configurations of a team."
    echo $0" remove <team> {<swimmer>}"
    echo "   Remove swimmers from a team."
    echo 
    echo "* Options"
    echo "  team:    A team name"
    echo "  times:   A CSV file containing all times for each swimmer."
    echo "  sex:     F for female, M for male teams."  
    exit
fi
opt=$1


case $opt in
    "new")
	
	### Teamnamen auswählen
	if [ -z "$2" ]; then
	    teamname=$(dialog --stdout --backtitle $BACKTITLE \
			      --title "Teamname" \
			      --inputbox "Geben Sie einen Teamnamen ein." \
			      0 0)
	    if test $? -eq 1
	    then
		dialog --clear && clear && exit
	    fi	    
	else
	    teamname=$2
	fi

	### Geschlecht auswählen
	if [ -z "$3" ]; then
	    gender=$(dialog --stdout \
			    --backtitle $BACKTITLE \
			    --title "" \
			    --radiolist "Geschlecht auswählen..." \
			    0 0 2 \
			    F "weiblich" off\
			    M "männlich" off)
	    #   X "mixed" off
	    #)
	    if test $? -eq 1
	    then
		dialog --clear && clear && exit
	    fi
	else
	    gender=$3
	fi

	### Zeitentabelle auswählen
	if [ -z "$4" ]; then
	   TIMES_FILE="dms-times.csv"
	else
	   TIMES_FILE=$4
	fi
	
	### Mannschaft auswählen.
	LST_ASWIMMER=()
	LST_ALLSWIMMER=()
	IFS_OLD=$IFS
	FS_OLS=$FS
	IFS=$'\n'#;FS='\n'
	CNT_ASWIMMER=0
	for swimmer in $(tools/extract_swimmer.rb $TIMES_FILE $gender)
	do
	    CNT_ASWIMMER=$(($CNT_ASWIMMER+1))
	    LST_ASWIMMER+=($CNT_ASWIMMER "$swimmer" off)
	    LST_ALLSWIMMER+=("$swimmer")
	done
	IFS=$IFS_OLD
	FS=$FS_OLD
	
	LST_TSWIMMER=($(dialog --stdout \
			       --backtitle $BACKTITLE \
			       --title "" \
			       --checklist "Mannschaft auswählen..." \
			       0 0 10 "${LST_ASWIMMER[@]}"))
	if test $? -eq 1
	then
	    dialog --clear && clear && exit
	fi	    

	### Punktetabelle auswählen
	if [ "$gender" = "$k_male" ]; then
	    files=basetimes/dms-base-male*.dat
	else
	    files=basetimes/dms-base-female*.dat
	fi
	LST_BTTS=() # Punktetabellen
	for bt in $files
	do
	    LST_BTTS+=("$bt" "")
	done
	
	timetable=$(dialog --stdout \
			   --backtitle $BACKTITLE \
			   --title "Punktetabelle" \
			   --menu "" 0 0 3\
			   "${LST_BTTS[@]}")
	
	if test $? -eq 1
	then
	    dialog --clear && clear && exit
	fi	    
	
	dialog --clear && clear

	mkdir -p teams/$teamname/
	echo $gender > teams/$teamname/gender
	touch teams/$teamname/team
	
	for idx in "${LST_TSWIMMER[@]}"
	do
	    echo "${LST_ALLSWIMMER[$(($idx-1))]}" >> teams/$teamname/team
	done
	timetable=$(echo $timetable| cut -c20-)
	timetable=${timetable%%.*}
	echo $timetable > teams/$teamname/basetimes
	
	;;

    "list")
	cd teams
	#ls teams | tr " " "\n"
	find . -maxdepth 1 -type d | tr -d "./" 
	cd ..
	;;

    "delete")
    	team=$2	
    	rm -Rf teams/$team
    	;;

    "remove")
	team=$2	
	i=0
	for var in "$@"
	do
	    (( i++ ))
	    if [ $i -gt 2 ]; then
		echo "Delete '$var' from team '$team'."
		cat teams/$team/team                | grep "$var" -v  > teams/$team/team.new
		cat teams/$team/dms-constraints.dat | grep "$var" -v  > teams/$team/dms-constraints.dat.new
		mv teams/$team/dms-constraints.dat teams/$team/dms-constraints.dat.old
		mv teams/$team/team teams/$team/team.old
		mv teams/$team/dms-constraints.dat.new teams/$team/dms-constraints.dat
		mv teams/$team/team.new teams/$team/team
	    fi
	done
	;;
    
    "show")
    	team=$2	
    	echo "Schwimmer:"
    	cat teams/$team/team
	echo ""
	echo Puntetabelle: $(cat teams/$team/basetimes)
    	;;
    
    "compute")
	if [ ! -z "$3" ]; then
	    timef=$3
	else
	    timef=dms-times.csv  
	fi
	
	team=$2

	
	gender=$(cat teams/$team/gender)
	basetimes=$(cat teams/$team/basetimes)

	echo "[DMS_OPT] Update DMS-Settings (Meeting, Events,...)"
	./tools/create_dms_settings.rb $gender 2 > teams/$team/dms-settings.dat
	echo "[DMS_OPT] Update Times for DMS-Computation"
	./tools/create_dms_gmpltimetable.rb $team $timef > teams/$team/dms-data.dat

	if [ ! -f teams/$team/dms-constraints.dat ]; then
	    echo "[DMS_OPT] Create a Default-Constraint File."
	    ./tools/create_dms_constraints.rb 2 $team > teams/$team/dms-constraints.dat
	else
	    echo "[DMS_OPT] Skipped creating a constraint file."
	fi

	echo "[DMS_OPT] Compute Team '$team' using times from $timef"
	
	glpsol -m dms.mod \
	       -d teams/$team/dms-settings.dat \
	       -d basetimes/dms-base-$basetimes.dat \
	       -d teams/$team/dms-constraints.dat \
	       -d teams/$team/dms-data.dat

	echo glpsol -m dms.mod \
	       -d teams/$team/dms-settings.dat \
	       -d basetimes/dms-base-$basetimes.dat \
	       -d teams/$team/dms-constraints.dat \
	       -d teams/$team/dms-data.dat
	;;
esac
