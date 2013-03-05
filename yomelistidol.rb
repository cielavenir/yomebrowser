#!/usr/bin/env ruby
#YomeBrowser Lister

#server number
NUMBER=22
#1=iPhone 2=Android
TERMINALKIND=2

require 'net/https'

SAX=2
case SAX
	when 0
		require 'rexml/document'
		require 'rexml/parsers/streamparser' 
		require 'rexml/streamlistener'
	when 1
		require 'rexml/document'
		require 'rexml/parsers/sax2parser'
		require 'rexml/sax2listener'
	when 2
		begin
			require 'libxml'
		rescue LoadError
			puts 'Falling back to REXML. Please: gem install libxml-ruby'
			SAX=0
			require 'rexml/document'
			require 'rexml/parsers/streamparser' 
			require 'rexml/streamlistener'
		end
end

body=''
https = Net::HTTP.new('idol.anime.biglobe.ne.jp',443)
https.use_ssl = true
https.start{
	https.request_get("/api/yome/#{NUMBER}/firstRun/getYomeList.php?terminalKind=#{TERMINALKIND}",{
		'Accept'=>'*/*',"User-Agent"=>"YomeColle"
	}){|response|
		response.read_body{|str|
			body << str
			STDERR.printf("%d\r",body.size)
		}
	}
}

open(File.dirname(__FILE__)+'/yomelistidol.xml','wb'){|f|f.puts body}

class YomeListener
	case SAX
		when 0 then include REXML::StreamListener
		when 1 then include REXML::SAX2Listener
		when 2 then include LibXML::XML::SaxParser::Callbacks
	end

	def initialize
		super
		@content=Hash.new{|h,k|h[k]=[]}
		@current_tag=[]
	end
	attr_reader :content

	def tag_start(tag,attrs)
		@current_tag.push(tag)
	end
	def start_element(uri,tag,qname,attrs) tag_start(tag,attrs) end
	alias_method :on_start_element, :tag_start
	def tag_end(tag)
		if (t=@current_tag.pop)!=tag then raise "xml is malformed /#{t}" end
	end
	def end_element(uri,tag,qname) tag_end(tag) end
	alias_method :on_end_element, :tag_end
	def cdata(text)
		if @current_tag[0..2]==['yomeRoot','yomeList','yomeInfo'] && ['name','actorName','titleName'].find{|e|e==@current_tag[3]}
			@content[@current_tag[3]] << text
		end
	end
	alias_method :on_cdata_block, :cdata
	def text(text)
		if @current_tag[0..2]==['yomeRoot','yomeList','yomeInfo'] && ['yomeId'].find{|e|e==@current_tag[3]}
			@content[@current_tag[3]] << text
		end
	end
	def characters(text) text(text) end
	alias_method :characters, :text
	alias_method :on_characters, :text
end

listener=YomeListener.new
case SAX
	when 0 then REXML::Parsers::StreamParser.new(body,listener).parse
	when 1 then parser=REXML::Parsers::SAX2Parser.new(body);parser.listen(listener);parser.parse
	when 2 then parser=LibXML::XML::SaxParser.string(body);parser.callbacks=listener;parser.parse
end
yomeList=listener.content['yomeId'].map(&:to_i).zip(listener.content['name'],listener.content['titleName'])
yomeList.sort_by{|e|e[0]}.each{|e|
	puts "#{e[0]}\t#{e[1]}\t[#{e[2]}]"
}

