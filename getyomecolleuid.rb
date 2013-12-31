#!/usr/bin/env ruby
require 'digest/sha1'
require 'openssl'

if ARGV.size<1
	puts "ruby getyomecolleuid.rb IMEI"
	exit
end
sha1=Digest::SHA1.hexdigest(ARGV[0])
str='0000000000000000'+sha1
aes=OpenSSL::Cipher::Cipher.new("AES-128-CBC")
aes.encrypt
aes.key='neBIG08-08-21#AP'
aes.iv='NEBIGVoice08Zero'
puts (aes.update(str)+aes.final).unpack('C*').map{|e|sprintf("%02x",e)}*''