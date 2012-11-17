#!/bin/sh
#YomeBrowser Downloader
#sh yomedl.sh N

#server number
export number=12

#check using WireShark maybe?
export userId=0000
export uid=abcdef

wget -O $1.zip -U YomeColle "https://anime.biglobe.ne.jp/api/yome/$number/download/getYomeData.php?userId=$userId&yomeId=$1&uid=$uid&terminalKind=2"
sleep 3
wget -O - -U YomeColle --post-data "userId=$userId&yomeId=$1&uid=$uid&terminalKind=2" "http://anime.biglobe.ne.jp/api/yome/$number/user/deleteYomeInfo.php"
sleep 2
