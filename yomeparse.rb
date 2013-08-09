#!/usr/bin/env ruby
#coding:utf-8
#YomeBrowser Parser
#ruby yomeparse.rb < conf/yome_data_N.xml > N.html
require 'rubygems'
require 'multisax'

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

listener=MultiSAX::Sax.parse($<,Class.new{
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
		if @current_tag[0..3]==['yomeRoot','cardList','cardInfo','changeImg'] && ['file'].find{|e|e==@current_tag[6]}
			@content['cardchg-'+@current_tag[6]]<<text
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
storyList=Hash[*listener.content['story-cardId'].map(&:to_i).zip(listener.content['story-text']).flatten]
voiceList=listener.content['voice-voiceId'].map(&:to_i).zip(listener.content['voice-voiceFile'],listener.content['voice-text'],listener.content['voice-cardId'].map(&:to_i))
voiceList2=Hash.new{|h,k|h[k]=[]}
voiceList.sort_by{|e|e[0]}.each{|e|
	voiceList2[e[3]]<<[e[0],e[1],e[2]]
}
cardList=listener.content['card-cardId'].map(&:to_i).zip(listener.content['card-cardName'],listener.content['card-file'])

print <<EOM
<!DOCTYPE html>
<html><head>
<meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
<title>YomeBrowser #{listener.content['name']}</title>
</head><body>
<p>
#{listener.content['yomeId']}: #{listener.content['name']} (CV:#{listener.content['actorName']}) [#{listener.content['titleName']}]
</p>
EOM

listener.content['cardchg-file'].each{|e|
	puts %Q(<a href="#{e}">#{e}</a><br>)
}
puts 'アクション<table border="1" style="border-collapse:collapse;">'
listener.actionList.each{|k,v|
	next if v.length==0
	puts %Q(<tr><td>#{k}</td><td><table border="1" style="border-collapse:collapse;">)
	if listener.actionVoiceList[k].length==0
		v.uniq.each{|e|
			puts "<tr><td>#{e}</td></tr>"
		}
	else
		v.uniq.zip(listener.actionVoiceList[k].uniq).each{|e|
			puts %Q(<tr><td>#{e[0]}</td><td><audio controls><source src="#{e[1]}" /></audio></td></tr>)
		}
	end
	puts "</table></td></tr>"
}
puts '</table>'

puts 'イベントアイテム・記念日<br><table border="1" style="border-collapse:collapse;">'
itemList.sort_by{|e|e[0]}.each{|e|
	item=items[e[0]]
	item=[e[0],''] if !item
	puts '<tr><td>'+item.join('</td><td>')+"</td><td>#{e[1]}</tr>"
}
puts '</table>'

print <<EOM
<table border="1" style="border-collapse:collapse;">
EOM
cardList.sort_by{|e|e[0]}.each{|e|
	puts %Q(<tr><td style="vertical-align:top">#{e[0]}: #{e[1]}<br><img src="#{e[2]}" alt="#{e[1]}"></td><td>)
	voiceList2[e[0]].each{|e0|
		puts %Q(#{e0[0]}: #{e0[2]}<br><audio controls><source src="#{e0[1]}"></audio><br>)
	}
	puts storyList[e[0]].gsub("\n\n","\n").gsub("\n\n","\n").gsub("\n",'<br>') if storyList[e[0]]
	puts "</td></tr>"
}
puts "</table></body></html>"
