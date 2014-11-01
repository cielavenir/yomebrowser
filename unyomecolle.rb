#!/usr/bin/env ruby
require 'find'
require 'fileutils'

if ARGV.size<2
	puts 'unyomecolle.rb source-dir/ target-dir/'
	exit
end
source=ARGV[0]
source+='/' if !source.end_with?('/')
target=ARGV[1]
target+='/' if !target.end_with?('/')
Find.find(source){|path|
	newpath=path.sub(source,target)
	puts newpath
	if File.directory?(path)
		FileUtils.mkdir_p(newpath)
	elsif path.end_with?('.csv')||path.end_with?('.xml')
		FileUtils.copy(path,newpath)
	else
		File.open(path,'rb'){|fin|
			str=fin.each_byte.with_index.map{|e,i|
					e^(i%0x7f+0x80)
			}.pack('C*')
			File.open(newpath,'wb'){|fout|
				fout.write(str)
			}
		}
	end
}
