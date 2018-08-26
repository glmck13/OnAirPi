#!/bin/ksh

PATH=$PATH:/sbin

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
	wpa_cli -i wlan0 scan
	Network=$(iwconfig 2>&1 | grep SSID | cut -f2 -d:); print ${Network//\"/} >$WIFI_INFO
	print $(wpa_cli list_networks | sed -e "/^[0-9]/!d" | cut -f2) >>$WIFI_INFO
	print $(wpa_cli scan_results | sed -e "/:/!d" | cut -f5) >>$WIFI_INFO
}

getEZConf () {
	unset EZTimeout

	scp -i $PEM $MCKLOGIN:$STATIONCONF $EZCONF || return

	set -A Conffile EZInfoName EZInfoGenre EZInfoDesc EZTimeout EZClip1 EZClip2 EZClip3 KeyStartCast KeyStopCast KeyLoadWifi KeyShutdown
	n=0; while read ${Conffile[$n]}
	do
		let n=$n+1
	done <$EZCONF

	cat - >$EZXML <<-EOF
	<ezstream>
		<url>$ICECASTURL</url>
		<sourcepassword>KurtVonnegutIce9!</sourcepassword>
		<format>MP3</format>
		<filename>stdin</filename>
		<stream_once>1</stream_once>
		<svrinfoname>$EZInfoName</svrinfoname>
		<svrinfogenre>$EZInfoGenre</svrinfogenre>
		<svrinfodescription>$EZInfoDesc</svrinfodescription>
		<svrinfopublic>0</svrinfopublic>
	</ezstream>
	EOF
}

exec >/dev/null 2>&1

trap : HUP INT QUIT

STATION=$(hostname)
PEM=~/etc/mckserver.pem
EZXML="/tmp/ez$$.xml"
EZCONF="/tmp/ez$$.conf"
EZMP3="/tmp/$STATION.mp3"

ICECASTURL="http://mckradio.dyndns.org:8000/$STATION.mp3"
MCKSRVRMP3="https://mckserver.dyndns.org/cdn/$STATION.mp3"
MCKLOGIN="ubuntu@mckserver.dyndns.org"
HTMLROOT="/var/www/html"
TMPMP3="/tmp/$STATION-lastClip.mp3"
STATIONCONF="$HTMLROOT/$STATION/ezstream.conf"
STATIONMKCAST="$HTMLROOT/cgi/mkechocast.sh"

LEDGREEN=4 LEDYELLOW=2 LEDRED=3

for led in $LEDGREEN $LEDYELLOW $LEDRED
do
	gpio -g mode $led out
	gpio -g write $led 0
done

gpio -g write $LEDRED 1

while true
do
configWifi; showWifi; getEZConf
[ "$EZTimeout" ] && break
sleep 5
done

gpio -g write $LEDRED 0; gpio -g write $LEDGREEN 0; gpio -g write $LEDYELLOW 1

typeset -l Key

irw | while read x Num Key Remote
do
	[ "$Num" -ne 0 ] && continue

	case ${Key#*_} in

	$KeyStopCast)
		[ "$(pgrep ezstream)" ] || continue
		pkill ezstream; wait %1
		gpio -g write $LEDGREEN 0; gpio -g write $LEDYELLOW 1
		scp -i $PEM $EZMP3 $MCKLOGIN:$TMPMP3
		ssh -i $PEM $MCKLOGIN "$STATIONMKCAST $TMPMP3 $EZClip1 $EZClip2 $EZClip3"
		rm -f $EZMP3
		;;

	$KeyStartCast)
		[ "$(pgrep ezstream)" ] && continue
		getEZConf
		if [ ! "$EZTimeout" ]; then
			gpio -g write $LEDRED 1
			continue
		fi
		timeout $EZTimeout rec -r 16k -t mp3 - | tee $EZMP3 | ezstream -c $EZXML &
		gpio -g write $LEDGREEN 1; gpio -g write $LEDYELLOW 0
		;;

	$KeyShutdown)
		gpio -g write $LEDRED 1
		sudo shutdown now
		;;

	$KeyLoadWifi)
		led=$(gpio -g read $LEDRED)
		timeout 2s gpio -g blink $LEDRED
		gpio -g write $LEDRED $led
		configWifi; showWifi
		;;

	esac
done
