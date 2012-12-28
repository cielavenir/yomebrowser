#!/bin/sh
#YomeBrowser Downloader
#sh yomedl.sh N

#server number
export number=1
#1=iPhone 2=Android
export terminalKind=2

#check using password recovery screen
export userId=0000
#iPhone: packet dump
#Android: use getyomecolleuid
export uid=abcdef

wget -O idol$1.zip -U YomeColle "https://idol.anime.biglobe.ne.jp/api/yome/$number/download/getYomeData.php?userId=$userId&yomeId=$1&uid=$uid&cardGroupId=1&terminalKind=$terminalKind"
sleep 3
wget -O - -U YomeColle --post-data "userId=$userId&yomeId=$1&uid=$uid&terminalKind=$terminalKind" "http://idol.anime.biglobe.ne.jp/api/yome/$number/user/deleteYomeInfo.php"
sleep 2

