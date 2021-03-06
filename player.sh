#!/bin/bash

CPCIP=${CPCIP:-192.168.1.22}
DB=${DB:-DSK}

shopt -s nocaseglob




function play {
	if test -z "$1"
	then
		echo You need to provide a filter >&2
		exit 1
	fi


	# Get the exact filename
	local fname="$1"
	if ! test -e "$fname"
	then
		fname=$(ls "$DB"/*"$fname"* 2>/dev/null) 
		if test -z "$fname"
		then
			echo unable to find a source file >&2
			exit 1
		fi
	fi


	case ${fname##*.} in
		dsk)
			playdsk "$fname"
			;;
		sna)
			playsna "$fname"
			;;
	esac
}


function playsna {
		xfer -y "$CPCIP" "$1"
}

function playdsk {
	local dsk="$1"
	# Extract the unique file
	#local fname=$(iDSK "$dsk" -l 2>&1 | grep '0$' | sed -e 's/0$//' | head -n 1)
	#Or a random one (better choice ?)
	local fnames=$(iDSK "$dsk" -l 2>&1 | grep '0$' | sed -e 's/0$//' -e 's/ //g')
	local nbfiles=$(echo "$fnames" | wc -l) 
	local fname=""
	if test $nbfiles -eq 1
	then
		# For one file, we extract this unique file and send it
		fname=$fnames
		echo "Use $fname in $dsk"
		iDSK "$dsk" -g "$fname" > /dev/null 2> /dev/null || (iDSK "$dsk" -g "$fname" ; exit -1)
		test -e "$fname" || (echo ERROR while extracting $fname from $dsk ; exit 1)
		
		# Play it
		local fname2=$(echo $fname| sed -e 's/ //g')
		mv "$fname" "$fname2"
		xfer -y "$CPCIP" "$fname2"
		rm "$fname2"
	else
		# For several files, we guess the filename to load, send the dsk and move in the dsk
		# XXX Here we are in a borderline case
		#     it would be better to send the DSK to the M4 and sk the M4 to do autolaunch.
		#     Any other solution (included the one implemented) is bad
		local currentext=""
		local selectedfname=""
		for fname in $fnames
		do
			local ext=${fname##*.} 
			if test "$ext" = "BAS"
			then
				selectedfname=$fname
				selectedext=$ext
			elif test "$ext" = ""
			then
				if test -z "$selectedext" -o "$selectedext" = "BIN"
				then
					selectedfname=$fname
					selectedext=$ext
				fi
			elif test "$ext" = "BIN"
			then
				if test -z "$selectedext" 
				then
					selectedfname=$fname
					selectedext=$ext

				fi
			fi
		done

		fname=$selectedfname
		cpcfname="playlist.dsk"
		cp "$dsk" "/tmp/$cpcfname"
		xfer -r "$CPCIP"
		sleep 3 #XXX No idea of the right amount of time to wait
		xfer -u "$CPCIP" "/tmp/$cpcfname" "/tmp/" 
		xfer -x "$CPCIP" "/tmp/$cpcfname/$fname"
		echo "Launch of $fname. If it is the wrong executable, reset (not shutdown) CPC and manually launch from it"

	fi

}

function check_db {
	if ! test -d "$DB" 
	then
		echo "[ERROR] Database $DB does not seem to exist" >&2
		exit 1
	fi
}

function list {
	check_db
	cd "$DB"
	ls *.{dsk,sna} -w 1 2>/dev/null | sed -e 's/.dsk$//i'
}

function random {
	while read fname
	do
		echo $fname
		play "$fname"
		read  -p "PRESS ENTER TO PLAY NEXT FILE" < /dev/tty
	done < <(list | sort -R)
}


function download  {
	mkdir -p "$DB"
	cd "$DB"

	# Download each file
	for url in $1
	do
		echo $url
		wget -c  --content-disposition "$url"
	done

	# Unrar the RAR files
	for file in *.rar
	do
		if test "$file" = '*.rar'
		then
			break
		fi
		unrar e -y "$file" || exit 1
		rm "$file"
	done

	# Unzip the zip files
	for file in *.zip
	do
		if test "$file" = '*.zip'
		then
			break
		fi
		unzip -o "$file" || exit 1
		rm "$file"
	done
}

SUTEKH_URLS="
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=1868
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=1890
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=2190
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=5097
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=5523
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=9431
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=12615
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=13589
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=22664
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=15670
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=16923
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=18348
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=18359
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=18415
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=18427
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=18477
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=18478
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=19006
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=19033
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=19688
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=20197
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=20407
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=20434
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=20435
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=20436
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=20437
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=20448
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=20506
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=20651
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=21997
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=21998
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=21999
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=22009
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=22096
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=22426
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=23076
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=23156
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=23455
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=24423
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=24465
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=24480
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=24497
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=24590
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=24865
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=24902
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=25547
http://www.cpcwiki.eu/forum/demos/wip-now-that's-what-i-call-chip-tunes-(winape)/?action=dlattach;attach=25644
"

MUSIC_PACK_URLS="
https://cpcrulez.fr/download.php?a=UoSlnJzWgsLl2M69gsbe29PNgLjn0cq5jsfo1ciHjsfo1cjKgrXgy5aIicbi
https://cpcrulez.fr/download.php?a=UoSlnpbWgsLl2M69gsbe29PNgLjn0cq5jsfo1ciHjsfo1cjKgrXgy5aIicbi
https://cpcrulez.fr/download.php?a=UoSlnpXWgsLl2M69gsbe29PNgLjn0cq5jsfo1ciHjsfo1cjKgrXgy5aIicbi
https://cpcrulez.fr/download.php?a=UoSlnpzWgsLl2M69gsbe29PNgLjn0cq5jsfo1ciHjsfo1cjKgrXgy5aIicbi
http://cpc.scifinet.org/?smd_process_download=1&download_id=231
"

case $1	in
	play)
		play "$2"
		;;
	list)
		list | column
		;;
	sync)
		#TODO add something to automatically download all these great songs (a list of links ?)
		;;
	random)
		random
		;;
	download)
		download "$SUTEKH_URLS"
		download "$MUSIC_PACK_URLS"
		;;
	help)
cat<<EOF
Music player for CPC over M4 by Krusty/Benediction.

This small script has been mainly created to listened on a real CPC the musics of SuTekH Of Epyteor.
It can of course be used for any other music spreaded in a similar way (but to DSK of SuTekH are way more interesting with animations).

Usage:

$0 play DSK/B2B6\ By\ Triace\ \(2017\)\(SuTekH\ Of\ Epyteor\).dsk  # Play the music contained in the specified DSK
$0 play b2b6 # Play the music in the DSK file in the database that continas the specified string
$0 list # List the collection
$0 random # Play the collection in a random order
$0 download # Download the DSK of SuTekH Of Epyteor


Known limitations:

 - Do not work with DSK containing several files
 - Random play needs to manually change the music
 - If the CPC player needs the user to press a key before playing the music you still have to do it

Pre-requisits:

 - iDSK
 - xfer

Optional :

 - unrar to unpack the downloaded files

Environement vaariables of interest:

 - CPCIP: IP address of the M4 card
 - DB: folder of the database of DSK


EOF
;;
	* )
		playdsk "$*"
		;;

esac
