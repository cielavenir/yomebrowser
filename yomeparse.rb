#!/usr/bin/env ruby
#YomeBrowser Parser
#ruby yomeparse.rb < conf/yome_data_N.xml > N.html

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

body=ARGF.read

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
		if @current_tag.length==2 && ['yomeId','name','actorName','titleName'].find{|e|e==@current_tag[1]}
			@content[@current_tag[1]]=text
		end
		if @current_tag[0..2]==['yomeRoot','cardList','cardInfo'] && ['cardId','cardName','file'].find{|e|e==@current_tag[3]}
			@content['card-'+@current_tag[3]]<<text
		end
		if @current_tag[0..2]==['yomeRoot','voiceList','voiceInfo'] && ['voiceId','voiceFile','text','cardId'].find{|e|e==@current_tag[3]}
			@content['voice-'+@current_tag[3]]<<text
		end
	end
	alias_method :on_cdata_block, :cdata
	def text(text)
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
voiceList=listener.content['voice-voiceId'].map(&:to_i).zip(listener.content['voice-voiceFile'],listener.content['voice-text'],listener.content['voice-cardId'].map(&:to_i))
voiceList2=Hash.new{|h,k|h[k]=[]}
voiceList.sort_by{|e|e[0]}.each{|e|
	voiceList2[e[3]]<<[e[0],e[1],e[2]]
}
cardList=listener.content['card-cardId'].map(&:to_i).zip(listener.content['card-cardName'],listener.content['card-file'])

print <<EOM
<!DOCTYPE html>
<html><head>
<title>YomeBrowser #{listener.content['name']}</title>
</head><body>
<p>
#{listener.content['yomeId']}: #{listener.content['name']} (CV:#{listener.content['actorName']}) [#{listener.content['titleName']}]
</p>
<table border="1" style="border-collapse:collapse;">
EOM
cardList.sort_by{|e|e[0]}.each{|e|
	puts %Q(<tr><td>#{e[0]}: #{e[1]}<br><img src="#{e[2]}" /></td><td>)
	voiceList2[e[0]].each{|e0|
		puts %Q(#{e0[0]}: #{e0[2]}<br><audio controls><source src="#{e0[1]}" /></audio><br>)
	}
	puts "</td></tr>"
}
puts "</table></body></html>"
