#!/bin/bash
kw_new="new"
k_male="M"
BACKTITLE="DMS-Aufstellung"
if [ -z "$1" ]; then
    echo $0" <command> args"
    echo $0" new [<team> [<gender>]]"
    echo $0" list"
    echo $0" delete  <team>"
    echo $0" compute <team>"
    echo $0" show <team>"
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
	
	### Mannschaft auswählen.
	LST_ASWIMMER=()
	LST_ALLSWIMMER=()
	IFS_OLD=$IFS
	FS_OLS=$FS
	IFS=$'\n'#;FS='\n'
	CNT_ASWIMMER=0
	for swimmer in $(tools/extract_swimmer.rb dms-times.csv $gender)
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
			       0 0 6 "${LST_ASWIMMER[@]}"))
	if test $? -eq 1
	then
	    dialog --clear && clear && exit
	fi	    

	### Punktetabelle auswählen
	if [ $gender=$k_male ]; then
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
	echo $timetable >> teams/$teamname/basetimes
	
	;;

    "list")
	ls teams | tr " " "\n"
	;;

    "delete")
    	team=$2	
    	rm -Rf teams/$team
    	;;
    
    "show")
    	team=$2	
    	echo "Schwimmer:"
    	cat teams/$team/team
	echo ""
	echo Puntetabelle: $(cat teams/$team/basetimes)
    	;;
    
    "compute")
	team=$2
	gender=$(cat teams/$team/gender)
	basetimes=$(cat teams/$team/basetimes)


	./tools/create_dms_settings.rb $gender 2 > teams/$team/dms-settings.dat
	./tools/create_dms_gmpltimetable.rb $team   > teams/$team/dms-data.dat

	if [ ! -f teams/$team/dms-constraints.dat ]; then
	    ./tools/create_dms_constraints.rb 2 $team > teams/$team/dms-constraints.dat
	else
		    echo "Skipped creating a constraint file."
	fi

	glpsol -m dms.mod \
	       -d teams/$team/dms-settings.dat \
	       -d basetimes/dms-base-$basetimes.dat \
	       -d teams/$team/dms-constraints.dat \
	       -d teams/$team/dms-data.dat
	;;
esac
