#!/bin/ksh

STATION=${1:?Enter station name}
MCKSRVR="https://mckserver.dyndns.org"
MCKSRVRMP3="$MCKSRVR/cdn/$STATION/echocast.mp3"
MCKSRVRM3U="$MCKSRVR/cdn/$STATION/icecast.m3u"

Audio="" Response=""

while true
do
	Header=$(curl -s --user-agent "AlexaMediaPlayer/" $MCKSRVRM3U)
	Header=$(curl -si --user-agent "AlexaMediaPlayer/" "$Header" | head -1)

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
