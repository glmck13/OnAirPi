#!/bin/ksh

PATH=$PWD:$PATH

[ "$REQUEST_METHOD" = "POST" ] && read -r QUERY_STRING

vars="$QUERY_STRING"
while [ "$vars" ]
do
	print $vars | IFS='&' read v vars
	[ "$v" ] && export $v
done

mount=$(urlencode -d "$mount")
station=${mount} station=${station#/} station=${station%%.*}

vars=$(print "$mount" | sed -e "s/^[^?]\+//" -e "s/?//")
while [ "$vars" ]
do
	print $vars | IFS='&' read v vars
	[ "$v" ] && export $v
done

auth=0
htpasswd -bv ../$station/.htpasswd "$user" "$pass" 2>/dev/null && auth=1

cat - <<EOF
icecast-auth-user: $auth
Content-type: text/html

<html></html>
EOF
