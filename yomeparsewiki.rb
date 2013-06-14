#!/usr/bin/env ruby
#coding: utf-8
#YomeBrowser Parser
#ruby yomeparse.rb < conf/yome_data_N.xml > N.html
require 'multisax'

require 'cgi'
if ARGV.size<2
	puts "yomeparsewiki.rb conf/yome_data_N.xml picture_prefix"
	exit
end
ID=ARGV[1]

m={
	'なでる'=>'なでた時のコメント',
	'超なでる'=>'超なでた時のコメント',
	'キス'=>'キスした時のコメント',
	'超キス'=>'超キスした時のコメント',
	'ツンツン'=>'ツンツンした時のコメント',
	'超ツンツン'=>'超ツンツンした時のコメント',
	'アラーム'=>'起こしてもらう時の反応',
	'話しかける'=>'話しかけた時の反応',
	'話しかける（テキスト）'=>'話しかけた時の反応',
}

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

listener=MultiSAX::Sax.parse(File.read(ARGV[0]),Class.new{
	include MultiSAX::Callbacks
	def initialize
		@content=Hash.new{|h,k|h[k]=[]}
		@actionList=Hash.new{|h,k|h[k]=[]}
		@actionVoiceList=Hash.new{|h,k|h[k]=[]}
		@current_tag=[]
		@current_action=''
	end
	attr_reader :content, :actionList, :actionVoiceList

	def sax_tag_start(tag,attrs)
		@current_tag.push(tag)
	end
	def sax_tag_end(tag)
		if (t=@current_tag.pop)!=tag then raise "xml is malformed /#{t}" end
	end
	def sax_cdata(text)
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
}.new)

gachas=Hash[*listener.content['gacha-gachaId'].zip(listener.content['gacha-gachaName']).flatten]
itemList=listener.content['item-itemId'].zip(listener.content['item-reactionText'])
storyList=Hash[*listener.content['item-itemId'].zip(listener.content['item-reactionText']).flatten]
voiceList=listener.content['voice-voiceId'].map(&:to_i).zip(listener.content['voice-voiceFile'],listener.content['voice-text'],listener.content['voice-cardId'].map(&:to_i))
voiceList2=Hash.new{|h,k|h[k]=[]}
voiceList.sort_by{|e|e[0]}.each{|e|
	voiceList2[e[3]]<<[e[0],e[1],e[2]]
}
cardList=listener.content['card-cardId'].map(&:to_i).zip(listener.content['card-cardName'],listener.content['card-file'])

#need to parse yomelist
#puts "**求婚PR"

listener.actionList.each{|k,v|
	puts "**#{m[k]}"
	#if listener.actionVoiceList[k].length==0
		puts '|「'+v.uniq.join("」|\n|「")+'」|'
	#end
	puts
}

puts '**イベントアイテム・記念日のアイテムをプレゼントした時のコメント'
itemList.sort_by{|e|e[0]}.each{|e|
	item=items[e[0]]
	item=['',e[0]] if !item
	voice=e[1].gsub('%month%','○').gsub('%nickname%','○○')
	puts '|'+item.join('|')+'|「'+voice+"」|\n"
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
