#!/usr/bin/env ruby
#coding: utf-8
#YomeBrowser Parser
#ruby yomeparse.rb < conf/yome_data_N.xml > N.html

require 'cgi'
ID='loeb'

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

levels={}
open(File.dirname(__FILE__)+'/level.csv'){|f|
	f.each_line{|line|
		a=line.chomp.split(',')
		levels[a[0]]=a[2]
	}
}
items={}
open(File.dirname(__FILE__)+'/itemlist.csv'){|f|
	f.each_line{|line|
		a=line.chomp.split(',')
		items[a[0]]=[a[1],a[2]]
	}
}

gachas={}

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
		@actionList=Hash.new{|h,k|h[k]=[]}
		@actionVoiceList=Hash.new{|h,k|h[k]=[]}
		@current_tag=[]
		@current_action=''
	end
	attr_reader :content, :actionList, :actionVoiceList

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
		if @current_tag[0..2]==['yomeRoot','cardList','cardInfo'] && ['cardId','cardName','file','gachaId','level'].find{|e|e==@current_tag[3]}
			@content['card-'+@current_tag[3]]<<text
		end
		if @current_tag[0..3]==['yomeRoot','cardList','cardInfo','changeImg'] && ['file'].find{|e|e==@current_tag[4]}
			@content['cardchg-'+@current_tag[4]]<<text
		end
		if @current_tag[0..2]==['yomeRoot','voiceList','voiceInfo'] && ['voiceId','voiceFile','text','cardId'].find{|e|e==@current_tag[3]}
			@content['voice-'+@current_tag[3]]<<text
		end
		if @current_tag[0..2]==['yomeRoot','gachaList','gachaInfo'] && ['gachaId','gachaName'].find{|e|e==@current_tag[3]}
			@content['gacha-'+@current_tag[3]]<<text.split('#')[0]
		end
		if @current_tag[0..2]==['yomeRoot','actionList','actionInfo'] && ['actionName'].find{|e|e==@current_tag[3]}
			@current_action=text
		end
		if @current_tag[0..6]==['yomeRoot','actionList','actionInfo','actTalkList','actTalkMoodInfo','actTalkInfoList','actTalkInfo'] && ['talkText'].find{|e|e==@current_tag[7]}
			@actionList[@current_action]<<text
		end
		if @current_tag[0..6]==['yomeRoot','actionList','actionInfo','actTalkList','actTalkMoodInfo','actTalkInfoList','actTalkInfo'] && ['voiceFile'].find{|e|e==@current_tag[7]}
			@actionVoiceList[@current_action]<<text
		end
		if @current_tag[0..2]==['yomeRoot','itemList','itemInfo'] && ['itemId','reactionText'].find{|e|e==@current_tag[3]}
			@content['item-'+@current_tag[3]]<<text
		end
		if @current_tag[0..2]==['yomeRoot','present4YomeList','present4YomeInfo'] && ['itemId'].find{|e|e==@current_tag[3]}
			str=@current_tag[3]
			str='reactionText' if str=='talkText'
			@content['item-'+str]<<text
		end
		if @current_tag[0..3]==['yomeRoot','present4YomeList','present4YomeInfo','presentTalkInfo'] && ['talkText'].find{|e|e==@current_tag[4]}
			str=@current_tag[4]
			str='reactionText' if str=='talkText'
			@content['item-'+str]<<text
		end
		if @current_tag[0..2]==['yomeRoot','storyList','storyInfo'] && ['cardId','text'].find{|e|e==@current_tag[3]}
			@content['story-'+@current_tag[3]]<<text
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

gachas=Hash[*listener.content['gacha-gachaId'].zip(listener.content['gacha-gachaName']).flatten]
itemList=listener.content['item-itemId'].zip(listener.content['item-reactionText'])
storyList=Hash[*listener.content['item-itemId'].zip(listener.content['item-reactionText']).flatten]
voiceList=listener.content['voice-voiceId'].map(&:to_i).zip(listener.content['voice-voiceFile'],listener.content['voice-text'],listener.content['voice-cardId'].map(&:to_i))
voiceList2=Hash.new{|h,k|h[k]=[]}
voiceList.sort_by{|e|e[0]}.each{|e|
	voiceList2[e[3]]<<[e[0],e[1],e[2]]
}
cardList=listener.content['card-cardId'].map(&:to_i).zip(listener.content['card-cardName'],listener.content['card-file'])

listener.actionList.each{|k,v|
	puts "**#{k}"
	#if listener.actionVoiceList[k].length==0
		puts '|「'+v.uniq.join("」|\n|「")+'」|'
	#end
	puts
}

puts '**イベントアイテム・記念日'
itemList.sort_by{|e|e[0]}.each{|e|
	item=items[e[0]]
	item=[e[0],''] if !item
	puts '|'+item.join('|')+'|「'+e[1]+"」|\n"
}

print <<EOM

&bold(){カード数#{cardList.size}　ボイス数#{voiceList.size}}

EOM
cardList.each_with_index{|e,i|
	cond=''
	str=listener.content['card-gachaId'].shift
	if i>0
		if str!='0'
			cond=' ('+gachas[str]+')'
		else
			str=listener.content['card-level'].shift
			cond=' (愛情度'+levels[str]+'で開放)'
		end
	end
	puts %Q(**No.#{i+1} #{e[1]}#{cond})
	#puts %Q(#image(http://www51.atwiki.jp/yomecolle/?cmd=upload&act=open&page=#{CGI.escape(listener.content['name'])}&file=#{ID}#{sprintf("%02d",i+1)}.jpg))
	puts %Q(#image(#{ID}#{sprintf("%02d",i+1)}.jpg))
	puts "|ボイス|CENTER:セリフ|"
	voiceList2[e[0]].each_with_index{|e0,j|
		puts "|CENTER:#{j+1}|「#{e0[2]}」|"
	}
	puts
}
