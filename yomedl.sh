#!/bin/sh
#YomeBrowser Downloader

#server number
export number=22
#1=iPhone 2=Android
export terminalKind=2

#check using password recovery screen
export userId=0000
#iPhone: packet dump
#Android: use getyomecolleuid
export uid=abcdef

if [ $# -ne 2 ]; then
	echo "sh yomedlidol.sh N group(usually 1)"
	exit 1
fi

wget -O $1_$2.zip -U YomeColle "https://anime.biglobe.ne.jp/api/yome/$number/download/getYomeData.php?userId=$userId&yomeId=$1&uid=$uid&cardGroupId=$2&terminalKind=$terminalKind"
sleep 3
wget -O - -U YomeColle --post-data "userId=$userId&yomeId=$1&uid=$uid&terminalKind=$terminalKind" "http://anime.biglobe.ne.jp/api/yome/$number/user/deleteYomeInfo.php"
sleep 2
