#!/bin/ksh

WIFI_CONF=/var/www/html/wifi.conf
WIFI_INFO=/var/www/html/wifi.info

configWifi() {
	[ -f "$WIFI_CONF" ] || return

	set -A Conffile Network Password Command
	n=0; while read ${Conffile[$n]}
	do
		let n=$n+1
	done <$WIFI_CONF; rm -f $WIFI_CONF

	unset Wifi; typeset -A Wifi
	wpa_cli list_networks | sed -e "/^[0-9]/!d" | while read netid ssid x
	do
		Wifi[$ssid]=$netid
	done

	netid=${Wifi[$Network]}

	case "$Command" in

	Add)
		if [ ! "$netid" ]; then
			netid=$(wpa_cli add_network | grep -iv interface)
			wpa_cli set_network $netid ssid \"$Network\"
			wpa_cli set_network $netid psk \"$Password\"
			wpa_cli set_network $netid scan_ssid 1
			wpa_cli set_network $netid key_mgmt WPA-PSK
			wpa_cli enable_network $netid
			wpa_cli save_config
		fi
		;;

	Delete)
		if [ "$netid" ]; then
			wpa_cli remove_network $netid
			wpa_cli save_config
		fi
		;;
	esac
}

showWifi() {
	Network=$(iwconfig 2>&1 | grep SSID | cut -f2 -d:); print ${Network//\"/} >$WIFI_INFO
	print $(wpa_cli list_networks | sed -e "/^[0-9]/!d" | cut -f2) >>$WIFI_INFO
	print $(wpa_cli scan_results | sed -e "/:/!d" | cut -f5) >>$WIFI_INFO
}

trap : HUP INT QUIT

exec >/dev/null 2>&1

KeyStopCast=power KeyShutdown=media KeyStartCast=mute KeyLoadWifi=home

LEDGREEN=4 LEDYELLOW=2 LEDRED=3

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
configWifi; showWifi
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

	$KeyStopCast)
		[ "$(pgrep ezstream)" ] || continue
		pkill ezstream; wait %1
		gpio -g write $LEDGREEN 0; gpio -g write $LEDYELLOW 1
		ssh -i $PEM $MCKLOGIN "rm -f $CDNMP3"
		scp -i $PEM $EZMP3 $MCKLOGIN:$CDNMP3
		rm -f $EZMP3
		;;

	$KeyStartCast)
		[ "$(pgrep ezstream)" ] && continue
		rec -r 16k -t mp3 - | tee $EZMP3 | ezstream -c $EZXML &
		gpio -g write $LEDGREEN 1; gpio -g write $LEDYELLOW 0
		;;

	$KeyShutdown)
		sudo shutdown now
		;;

	$KeyLoadWifi)
		configWifi; showWifi
		;;

	esac
done
