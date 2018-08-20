#!/bin/ksh

PATH=$PWD:$PATH

STATION="${PWD##*/}"
RECORDING="${STATION}.mp3"
EZCONF="ezstream.conf"

[ "$REQUEST_METHOD" = "POST" ] && read -r QUERY_STRING

vars="$QUERY_STRING"
while [ "$vars" ]
do
	print $vars | IFS='&' read v vars
	[ "$v" ] && export $v
done

case "$Command" in
	Update)
		cat - <<-EOF >$EZCONF
		$(urlencode -d "$EZInfoName")
		$(urlencode -d "$EZInfoGenre")
		$(urlencode -d "$EZInfoDesc")
		EOF
		;;
	Delete)
		cd ../cdn; rm -f $RECORDING; cd - >/dev/null
		;;
esac

set -A Conffile EZInfoName EZInfoGenre EZInfoDesc
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

<input type="submit" name="Command" value="Update" /><br>

<hr>
Recordings:
$(
	cd ../cdn
	[ -f $RECORDING ] && print "<p>$(ls -l $RECORDING)<br><audio controls><source src=/${PWD##*/}/$RECORDING></audio></p>"
	cd - >/dev/null
)

<br><input type="submit" name="Command" value="Delete" /><br>

</form>

</html>
EOF
