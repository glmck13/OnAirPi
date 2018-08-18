#!/bin/ksh

trap : HUP INT QUIT

exec >/dev/null 2>&1

LEDGREEN=4
LEDYELLOW=2
LEDRED=3

for led in $LEDGREEN $LEDYELLOW $LEDRED
do
	gpio -g mode $led out
	gpio -g write $led 0
done

gpio -g write $LEDRED 1

PEM=~/etc/mckserver.pem
EZXML="/tmp/ez$$.xml"
EZCONF="/tmp/ez$$.conf"
EZMP3="/tmp/$(hostname).mp3"

ICECASTURL="http://mckradio.dyndns.org:8000/$(hostname).mp3"
MCKSRVRMP3="https://mckserver.dyndns.org/cdn/$(hostname).mp3"
MCKLOGIN="ubuntu@mckserver.dyndns.org"
HTMLROOT="/var/www/html"
CDNMP3="$HTMLROOT/cdn/$(hostname).mp3"
CDNM3U="$HTMLROOT/cdn/$(hostname).m3u"
CLIENTCONF="$HTMLROOT/$(hostname)/ezstream.conf"

while true
do
scp -i $PEM $MCKLOGIN:$CLIENTCONF $EZCONF && break
sleep 5
done

ssh -i $PEM $MCKLOGIN "rm -f $CDNM3U; echo $ICECASTURL >$CDNM3U"

gpio -g write $LEDRED 0

. $EZCONF

EZINFONAME=${EZInfoName_SAVE:-Name}
EZINFOGENRE=${EZInfoGenre_SAVE:-Genre}
EZINFODESC=${EZInfoDesc_SAVE:-Description}

cat - >$EZXML <<-EOF
<ezstream>
	<url>$ICECASTURL</url>
	<sourcepassword>KurtVonnegutIce9!</sourcepassword>
	<format>MP3</format>
	<filename>stdin</filename>
	<stream_once>1</stream_once>
	<svrinfoname>$EZINFONAME</svrinfoname>
	<svrinfogenre>$EZINFOGENRE</svrinfogenre>
	<svrinfodescription>$EZINFODESC</svrinfodescription>
	<svrinfopublic>1</svrinfopublic>
</ezstream>
EOF

typeset -l Key

gpio -g write $LEDGREEN 0; gpio -g write $LEDYELLOW 1

irw | while read x Num Key Remote
do
	[ "$Num" -ne 0 ] && continue

	case ${Key#*_} in

	power)
		[ "$(pgrep ezstream)" ] || continue
		pkill ezstream; wait %1
		gpio -g write $LEDGREEN 0; gpio -g write $LEDYELLOW 1
		ssh -i $PEM $MCKLOGIN "rm -f $CDNMP3"
		scp -i $PEM $EZMP3 $MCKLOGIN:$CDNMP3
		rm -f $EZMP3
		;;

	mute)
		[ "$(pgrep ezstream)" ] && continue
		rec -r 16k -t mp3 - | tee $EZMP3 | ezstream -c $EZXML &
		gpio -g write $LEDGREEN 1; gpio -g write $LEDYELLOW 0
		;;

	home)
		sudo shutdown now
		;;

	esac
done
