#!/usr/bin/env ruby
#YomeBrowser Lister

#server number
NUMBER=25
#1=iPhone 2=Android
TERMINALKIND=2

require 'net/https'
require 'uri'
require 'multisax'
uri=URI.parse("https://idol.anime.biglobe.ne.jp/api/yome/#{NUMBER}/firstRun/getYomeList.php?terminalKind=#{TERMINALKIND}")

body=''
https = Net::HTTP.new(uri.host,443)
https.use_ssl = true
https.start{
	https.request_get(uri.path+'?'+uri.query,{
		'Accept'=>'*/*',"User-Agent"=>"YomeColle"
	}){|response|
		response.read_body{|str|
			body << str
			STDERR.printf("%d\r",body.size)
		}
	}
}

open(File.dirname(__FILE__)+'/yomelistidol.xml','wb'){|f|f.puts body}

listener=MultiSAX::Sax.parse(body,Class.new{
	include MultiSAX::Callbacks
	def initialize
		@content=Hash.new{|h,k|h[k]=[]}
		@current_tag=[]
	end
	attr_reader :content

	def sax_tag_start(tag,attrs)
		@current_tag.push(tag)
	end
	def sax_tag_end(tag)
		if (t=@current_tag.pop)!=tag then raise "xml is malformed /#{t}" end
	end
	def sax_cdata(text)
		if @current_tag[0..2]==['yomeRoot','yomeList','yomeInfo'] && ['name','actorName','titleName'].find{|e|e==@current_tag[3]}
			@content[@current_tag[3]] << text
		end
	end
	def sax_text(text)
		if @current_tag[0..2]==['yomeRoot','yomeList','yomeInfo'] && ['yomeId'].find{|e|e==@current_tag[3]}
			@content[@current_tag[3]] << text
		end
	end
}.new)
yomeList=listener.content['yomeId'].map(&:to_i).zip(listener.content['name'],listener.content['titleName'])
yomeList.sort_by{|e|e[0]}.each{|e|
	puts "#{e[0]}\t#{e[1]}\t[#{e[2]}]"
}

