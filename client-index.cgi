#!/bin/ksh

PATH=$PWD:$PATH
WIFI_CONF=wifi.conf
WIFI_INFO=wifi.info

[ "$REQUEST_METHOD" = "POST" ] && read -r QUERY_STRING

vars="$QUERY_STRING"
while [ "$vars" ]
do
	print $vars | IFS='&' read v vars
	[ "$v" ] && export $v
done

if [ "$Command" ]; then
	cat - <<-EOF >$WIFI_CONF
	$(urlencode -d "$Network")
	$(urlencode -d "$Password")
	$(urlencode -d "$Command")
	EOF
fi

if [ -f "$WIFI_INFO" ]; then
	set -A Infofile Active Configured Available
	n=0; while read ${Infofile[$n]}
	do
		let n=$n+1
	done <$WIFI_INFO
fi

cat - <<-EOF
Content-type: text/html

<html>
<h1>Wifi Setup</h1>
<form action="$SCRIPT_NAME" method="post">
<p>
Network: <input type="text" size=20 name="Network">
Password: <input type="password" size=20 name="Password">
</p>
<input type="submit" name="Command" value="Add" />
<input type="submit" name="Command" value="Delete" />
</form>
<p>Active: $Active</p>
<p>Configured: $Configured</p>
<p>Available: $Available</p>
</html>
EOF
