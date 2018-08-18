#!/bin/ksh

PATH=$PWD:$PATH

[ "$REQUEST_METHOD" = "POST" ] && read -r QUERY_STRING

vars="$QUERY_STRING"
while [ "$vars" ]
do
	print $vars | IFS='&' read v vars
	[ "$v" ] && export $v
done

case "$Intent" in

	StreamAudio)
		Response=$(radioServer.sh $Station)
		;;

	*)
		Response="<html><body><p>I don't know how to handle $Intent requests.</p></body></html>"
		;;
	esac

cat - <<EOF
Content-type: text/html

$Response
EOF
