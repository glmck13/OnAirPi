#!/bin/ksh

PATH=$PWD:$PATH

[ "$REQUEST_METHOD" = "POST" ] && read -r QUERY_STRING

vars="$QUERY_STRING"
while [ "$vars" ]
do
	print $vars | IFS='&' read v vars
	[ "$v" ] && export $v
done

cat - <<EOF
icecast-auth-user: 1
Content-type: text/html

<html></html>
EOF
