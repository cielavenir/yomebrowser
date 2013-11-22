#!/usr/bin/ruby
#YomeBrowser Downloader

#server number
NUMBER=28
#1=iPhone 2=Android
TERMINALKIND=2

require 'rubygems'
require 'net/https'
load File.expand_path(File.dirname(__FILE__)+'/yomedlidol.conf')

if ARGV.size<2
	puts 'yomedlidol.rb N group(usually 1)'
	puts 'Note: You must have at least one vacancy.
	puts 'Also, please never specify yome you are adding to application, or your progress will be lost completely.'
	puts 'If so, you can dump yome data from your mobile.'
	exit
end
yomeId=ARGV[0]
cardGroupId=ARGV[1]
destarc=yomeId+'_'+cardGroupId+'.zip'

File.open(destarc,'wb'){|f|
	https = Net::HTTP.new('idol.anime.biglobe.ne.jp',443)
	https.use_ssl = true
	https.start{
		puts 'Downloading...'

		https.request_get("/api/yome/#{NUMBER}/download/getYomeData.php?userId=#{USERID}&yomeId=#{yomeId}&uid=#{UID}&cardGroupId=#{cardGroupId}&terminalKind=#{TERMINALKIND}",{
			'Accept'=>'*/*','User-Agent'=>'YomeColle'
		}){|response|
			response.read_body{|str|
				f << str
				STDERR.printf("%d\r",f.size)
			}
		}

		puts
		sleep(2)
		puts 'Unregistering...'

		body=https.post("/api/yome/#{NUMBER}/user/deleteYomeInfo.php","userId=#{USERID}&yomeId=#{yomeId}&uid=#{UID}&terminalKind=#{TERMINALKIND}",{
			'Accept'=>'*/*','User-Agent'=>'YomeColle'
		}).response.body
		if body=~/result/
			puts 'OK.'
		else
			body=~/^\<description\>\<!\[CDATA\[(.+)\]\]\>\<\/description\>$/
			puts 'Error: '+$1
		end

		sleep(1)
	}
}
begin
	File.unlink(destarc) if FileTest.size(destarc)<1000
rescue; end

