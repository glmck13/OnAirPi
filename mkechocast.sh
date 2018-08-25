#!/bin/ksh

INFILE=${1:?Enter recording file}
STATION=${INFILE##*/} STATION=${STATION%-*}
HTMLROOT=/var/www/html

cd $HTMLROOT/cdn/$STATION
rm -f ${INFILE##*-} echocast.mp3
cp $INFILE ${INFILE##*-}; rm -f $INFILE

playlist=""
for f in $*
do
[ -f $f.mp3 ] && playlist+=" $f.mp3"
done

if [ "$playlist" ]; then
	sox $playlist echocast.mp3
fi
