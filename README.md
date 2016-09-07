## yomebrowser
yomebrowser project is now over.

## technical info

### flaw
- They used HTTPS for most communications, but they did use HTTP for deleting yome from slots.
- This flaw could be used to retrive uid.

### archive
- archive is usual zip.
- internal files are encrypted.
  - xored by (i%0x7f+0x80), where i is the file offset (0-indexed).

### uid
#### Android
- encrypt(str="0000000000000000"+sha1(IMEI),cipher="AES-128-CBC",key="neBIG08-08-21#AP",iv="NEBIGVoice08Zero")
- some devices such as walkman does not have IMEI... I don't know about those.

#### iPhone
- Something around UIID (universal install ID, NOT universal device ID) is used. So you need to use the flaw above to retrive uid.

### communication
- `https://api.yomecolle.jp/api/yome/30/...`.
- User-Agent must start with `YomeColle`.

It is up to you how to parse and show the yome xml. I, myself, tried to use audio tag for interoperability.

