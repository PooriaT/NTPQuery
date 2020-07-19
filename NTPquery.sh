#!/bin/bash

#Default Directory
homeDir=/home/pooria/NTPQ

#ntpStatus=`service ntp status | sed -n '3p | awk {print $2}`

#if [[ "$ntpStatus == inactive ]]
#then
	#echo HELLO
	#service ntp start
#fi

#Writing the NTP output in a new text file
ntpq -p > `echo $homeDir`/NTPQ.txt

#Stopping the ntpd service
/etc/init.d/ntp stop


#variable
UP=1.000
newUP=0.001
minToSec=1000


echo "remote	refid	st	t	when	poll	reach	delay	offset	jitter" > `echo $homeDir`/NTPQ_$(date +%F).csv

for i in {3..98}
do
	offset=$(awk '{print $9}' `echo $homeDir`/NTPQ.txt | sed -n $i'p' | sed 's/^-//')
	IP=$(awk '{print $1}' `echo $homeDir`/NTPQ.txt | sed -n $i'p' | sed 's/^[#+x*-]//')
	if [[ $offset > $UP ]]
	then
		#echo $offset
		for j in {1..3}
		do
			new_Offset=`ntpdate $IP | awk '{print $10}'`
			newOffset=`echo $new_Offset | sed 's/^-//'`
			
			if [[ $newOffset < $newUP ]]
			then
				sed -n $i'p' `echo $homeDir`/NTPQ.txt | awk '{for(i=1; i<9; i++) printf($i "\t");}' > `echo $homeDir`/temp.txt
				echo "$new_Offset * 1000" | bc >> `echo $homeDir`/temp.txt
				echo -e '\t' >> `echo $homeDir`/temp.txt
				awk '{print $10}' `echo $homeDir`/NTPQ.txt | sed -n $i'p' >> `echo $homeDir`/temp.txt
				cat `echo $homeDir`/temp.txt | tr '\n' ' ' >> `echo $homeDir`/NTPQ_$(date +%F).csv
				echo " " >> `echo $homeDir`/NTPQ_$(date +%F).csv

				break
			fi

			if [[ $j == 3  ]]
				then
				if [[ $newOffset > $UP  ]]
				then
					sed -n $i'p' `echo $homeDir`/NTPQ.txt >> `echo $homeDir`/NTPQ_$(date +%F).csv
				fi
			fi
		done
	else
		
		sed -n $i'p' `echo $homeDir`/NTPQ.txt | awk '{for(i=1; i<11; i++) printf($i "\t");}' >> `echo $homeDir`/NTPQ_$(date +%F).csv
		echo " " >> `echo $homeDir`/NTPQ_$(date +%F).csv
	fi

done


#Removing the redundant file
rm -rf `echo $homeDir`/temp.txt

#Starting the ntpd service
/etc/init.d/ntp restart
