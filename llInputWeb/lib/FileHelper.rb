Tab="\t"
New_Line="\n"
SpecialChar = "×"

def Read(fileName)
	File.open(fileName,"r", :encoding => 'UTF-8') do |io|
		lines=[]
		io.each do |line|
			array = line.chomp.split(Tab)                            
			lines << array
		end
		lines
	end
end

def Write(fileName, data)
	return if !data

	dirName=File.dirname(fileName)      
	ensureDir(dirName)

	File.open(fileName, "w", :encoding => 'UTF-8') do |io|
		data.each_with_index do |line,i|
			line_str = line.join(Tab).gsub(/\n/,SpecialChar)
			io.write line_str
			if i != data.count - 1            
				io.write(New_Line)
			end
		end
	end
end

def ensureDir(dirName)
	if(!File.directory?(dirName))		
		Dir.mkdir(dirName)	
	end
end

require 'pathname'
require 'rubygems'  
require 'zip/zipfilesystem'  

def compress(source,target)
	# begin
	Zip::ZipFile.open target, Zip::ZipFile::CREATE do |zip|  
		add_file_to_zip(source, zip,Pathname.new(source).basename)  
	end  
 #  rescue Zip::ZipEntryExistsError
	# return
 #  end
end  

def add_file_to_zip(file_path, zip,path_in_zip)  
	if File.directory?(file_path)  
		Dir.foreach(file_path) do |sub_file_name|  
			add_file_to_zip("#{file_path}/#{sub_file_name}", zip, File.join(path_in_zip,sub_file_name)) unless sub_file_name == '.' or sub_file_name == '..'  
		end  
	else  
		# 第一个参数指定zip文件中的路径，第二个参数指定要被压缩的文件的路径。 
		zip.add(path_in_zip,file_path)  
	end  
end 
