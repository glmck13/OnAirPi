#!/bin/ksh

PATH=$PWD:$PATH

STATION="${PWD##*/}"
LASTCLIP="/cdn/$STATION/lastClip.mp3"
CLIPA="/cdn/$STATION/clipA.mp3"
CLIPB="/cdn/$STATION/clipB.mp3"
ECHOCAST="/cdn/$STATION/echocast.mp3"
EZCONF="ezstream.conf"

[ "$REQUEST_METHOD" = "POST" ] && read -r QUERY_STRING

vars="$QUERY_STRING"
while [ "$vars" ]
do
	print $vars | IFS='&' read v vars
	[ "$v" ] && export $v
done

case "$Command" in
	UpdateEZInfo)
		cat - <<-EOF >$EZCONF
		$(urlencode -d "$EZInfoName")
		$(urlencode -d "$EZInfoGenre")
		$(urlencode -d "$EZInfoDesc")
		$(urlencode -d "$EZTimeout")
		$(urlencode -d "$EZClip1")
		$(urlencode -d "$EZClip2")
		$(urlencode -d "$EZClip3")
		$(urlencode -d "$KeyStartCast")
		$(urlencode -d "$KeyStopCast")
		$(urlencode -d "$KeyLoadWifi")
		$(urlencode -d "$KeyShutdown")
		EOF
		;;

	GetUrl)
		rm -f ../$LASTCLIP
		curl -skL "$(urlencode -d "$UrlClip")" -o - | sox -t mp3 - -r16k ../$LASTCLIP
		;;

	DeleteLast)
		rm -f ../$LASTCLIP
		;;

	CopyLastToA)
		cp ../$LASTCLIP ../$CLIPA
		;;

	CopyLastToB)
		cp ../$LASTCLIP ../$CLIPB
		;;

	DeleteClipA)
		rm -f ../$CLIPA
		;;

	DeleteClipB)
		rm -f ../$CLIPB
		;;

	DeleteEcho)
		rm -f ../$ECHOCAST
		;;

	CopyEchoToA)
		cp ../$ECHOCAST ../$CLIPA
		;;

	CopyEchoToB)
		cp ../$ECHOCAST ../$CLIPB
		;;
esac

set -A Conffile EZInfoName EZInfoGenre EZInfoDesc EZTimeout EZClip1 EZClip2 EZClip3 KeyStartCast KeyStopCast KeyLoadWifi KeyShutdown
n=0; while read ${Conffile[$n]}
do
	let n=$n+1
done <$EZCONF

cat - <<-EOF
Content-type: text/html

<html>

<h1>$STATION</h1>
<form action="$SCRIPT_NAME" method="post">

<p>Station Name:<br><input type="text" size=40 name="EZInfoName" value="$EZInfoName"></p>

<p>Station Genre:<br><input type="text" size=40 name="EZInfoGenre" value="$EZInfoGenre"></p>

<p>Station Description:<br><textarea rows=2 cols=40 name="EZInfoDesc" />$EZInfoDesc</textarea></p>

<p>
Playlist Order:
$(
n=1; while [ $n -le 3 ]
do
print "<select name=\"EZClip$n\">"
print "<option value=\"\" $(eval [ ! \"\${EZClip$n}\" ] && print selected)></option>"
for c in lastClip clipA clipB
do
print "<option value=\"$c\" $(eval [ \"\${EZClip$n}\" = $c ] && print selected)>$c</option>"
done
print "</select>"
let n=$n+1
done
)
</p>

<p>
Timeout: <select name="EZTimeout">
$(
for t in 1m 10m 30m 60m 90m 3h
do
print "<option value=\"$t\" $([ $EZTimeout = $t ] && print selected)>$t</option>"
done
)
</select>
</p>

<p>
KeyStartCast: <input type="text" size=8 name="KeyStartCast" value="$KeyStartCast">
KeyStopCast: <input type="text" size=8 name="KeyStopCast" value="$KeyStopCast">
KeyLoadWifi: <input type="text" size=8 name="KeyLoadWifi" value="$KeyLoadWifi">
KeyShutdown: <input type="text" size=8 name="KeyShutdown" value="$KeyShutdown">
</p>

<input type="submit" name="Command" value="UpdateEZInfo" /><br>

<hr>

<p>
Url:
<input type="text" size=40 name="UrlClip">
<input type="submit" name="Command" value="GetUrl" /><br>
</p>

<p>
LastClip:
$(
	[ -f ../$LASTCLIP ] && print "<p>$(ls -l ../$LASTCLIP)<br><audio controls><source src=$LASTCLIP></audio>"
)
<br>
<input type="submit" name="Command" value="DeleteLast" />
<input type="submit" name="Command" value="CopyLastToA" />
<input type="submit" name="Command" value="CopyLastToB" />
</p>

<p>
ClipA:
$(
	[ -f ../$CLIPA ] && print "<p>$(ls -l ../$CLIPA)<br><audio controls><source src=$CLIPA></audio>"
)
<br>
<input type="submit" name="Command" value="DeleteClipA" />
</p>

<p>
ClipB:
$(
	[ -f ../$CLIPB ] && print "<p>$(ls -l ../$CLIPB)<br><audio controls><source src=$CLIPB></audio>"
)
<br>
<input type="submit" name="Command" value="DeleteClipB" />
</p>

<p>
EchoClip:
$(
	[ -f ../$ECHOCAST ] && print "<p>$(ls -l ../$ECHOCAST)<br><audio controls><source src=$ECHOCAST></audio>"
)
<br>
<input type="submit" name="Command" value="DeleteEcho" />
<input type="submit" name="Command" value="CopyEchoToA" />
<input type="submit" name="Command" value="CopyEchoToB" />
</p>

</form>

</html>
EOF
