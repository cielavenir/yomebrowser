#!/bin/sh
#YomeBrowser Downloader

#server number
export number=30
#1=iPhone 2=Android
export terminalKind=2

DIR="`dirname "$0"`"
eval `sed -e '/^#/d' -e 's/UID=/export uid=/' -e 's/USERID=/export userId=/' "${DIR}/yomedl.conf"`

if [ $# -ne 2 ]; then
	echo "sh yomedl.sh N group(usually 1)"
	echo "Note: You must have at least one vacancy."
	echo "Also, please never specify yome you are adding to application, or your progress will be lost completely."
	echo "If so, you can dump yome data from your mobile."
	exit 1
fi

wget -O $1_$2.zip -U YomeColle "https://yomecolle.jp/api/yome/$number/download/getYomeData.php?userId=$userId&yomeId=$1&uid=$uid&cardGroupId=$2&terminalKind=$terminalKind"
sleep 2
wget -O - -U YomeColle --post-data "userId=$userId&yomeId=$1&uid=$uid&terminalKind=$terminalKind" "http://yomecolle.jp/api/yome/$number/user/deleteYomeInfo.php"
sleep 1
