#!/bin/ksh

PATH=$PWD:$PATH

CLIENT="${PWD##*/}"
RECORDING="${CLIENT}.mp3"
SETTINGS="ezstream.conf"

[ "$REQUEST_METHOD" = "POST" ] && read -r QUERY_STRING

vars="$QUERY_STRING"
[ "$HTTP_COOKIE" ] && vars="${vars}&${HTTP_COOKIE}"
while [ "$vars" ]
do
	print $vars | IFS='&' read v vars
	[ "$v" ] && export $v
done

. $SETTINGS; rm -f $SETTINGS
for v in EZInfoName EZInfoGenre EZInfoDesc
do
	export $v="$(eval urlencode -d '$'${v})"
	[ ! "$(eval print '$'${v})" ] && export $v="$(eval print '$'${v}_SAVE)"
	export ${v}_SAVE="$(eval print '$'${v})"
	print ${v}_SAVE=\"$(eval print '$'${v}_SAVE)\" >>$SETTINGS
done
chmod +x $SETTINGS

case "$Command" in
	Update)
		;;
	Delete)
		cd ../cdn; rm -f $RECORDING; cd - >/dev/null
		;;
esac

cat - <<EOF
Content-type: text/html

<html>

<h1>$CLIENT</h1>
<form action="$SCRIPT_NAME" method="post">

<p>
<b>Stream Name:</b><br>
<input type="text" size=40 name="EZInfoName" value="$EZInfoName">
</p>

<p>
<b>Stream Genre:</b><br>
<input type="text" size=40 name="EZInfoGenre" value="$EZInfoGenre">
</p>

<p>
<b>Stream Description:</b>
<br><textarea rows=2 cols=40 name="EZInfoDesc" />$EZInfoDesc</textarea>
</p>

<input type="submit" name="Command" value="Update" /><br>

<hr>
<b>Recordings:</b>
$(
	cd ../cdn
	[ -f $RECORDING ] && print "<p>$(ls -l $RECORDING)<br><audio controls><source src=/${PWD##*/}/$RECORDING></audio></p>"
	cd - >/dev/null
)

<br><input type="submit" name="Command" value="Delete" /><br>

</form>

</html>
EOF
