#!/bin/ksh

STATION=${1:?Enter station name}
ICECASTURL="http://mckradio.dyndns.org:8000"
ICECASTMP3=$ICECASTURL/$STATION.mp3
MCKSRVR="https://mckserver.dyndns.org"
MCKSRVRMP3="$MCKSRVR/cdn/$STATION.mp3"
MCKSRVRM3U="$MCKSRVR/cdn/$STATION.m3u"

Audio="" Response=""

while true
do
	Header=$(curl -si $ICECASTMP3 | head -1)

	if [[ $Header == *200\ OK* ]]; then
		Audio=$MCKSRVRM3U
		Response="Accessing live broadcast"
		break
	fi

	Header=$(curl -si --user-agent "AlexaMediaPlayer/" $MCKSRVRMP3 | head -4)

	if [[ $Header == *200\ OK* ]]; then
		Audio=$MCKSRVRMP3
		DateSaved=$(print "$Header" | sed -e "/^Last-Modified: /!d" -e "s/^Last-Modified: //")
		DateSaved=$(date -d "$DateSaved" "+%a %b %d at %l:%M %p")
		Response="Accessing recording from $DateSaved"
		break
	fi

	Response="Stream not found"
	break
done

cat - <<EOF
<html><body>
$([ "$Response" ] && print "<p>$Response</p>")
$([ "$Audio" ] && print "<audio controls><source src=\"$Audio\"></audio>")
</body></html>
EOF
