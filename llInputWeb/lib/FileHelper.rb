Tab="\t"
New_Line="\n"
SpecialChar = "×"

require 'ExcelHelper.rb'
# $my_log = Logger.new("/home/yy/myGit/LL/llInputWeb/log/readfile.log")
def Read(fileName)
	return nil if !fileName
	ext = File.extname(fileName)
	return read_xlsx(fileName) if ext && ext.include?(".xlsx")
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
	return false if !data

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
	true
end

def ensureDir(dirName)
	if(!File.directory?(dirName))		
		Dir.mkdir(dirName)	
	end
end

def try_save_and_parse_data(file,dirN,bAddIp,mutex,length_for_check)
	temp_path = uploadFile(file,dirN,bAddIp,mutex)
	return nil if !temp_path 
	begin
		data = []
		mutex.synchronize{				
			data = Read(temp_path)	
			data = ensure_data(data,length_for_check)
			return nil if !data || data.length == 0 
			data.shift
		}
		return data
	rescue 
		return nil
	end
end

def ensure_data(data,length_for_check)
	return nil if !data
	result = []
	data.each_with_index do |line,i|
		return nil if !line
		if  line.length == length_for_check+1
		elsif line.length != length_for_check
			return nil
		else 
			line << ""
		end
		result << line
	end
	result
end

def uploadFile(file,dirN,bAddIp,mutex)
	if !file.original_filename.empty?
		dirName="#{Rails.root}/public/input" 
		mutex.synchronize{
			ensureDir(dirName)
			if dirN
				dirName = File.join(dirName,dirN)
				ensureDir(dirName)
			end
		}
		begin
			file_name = bAddIp ? bAddIp+file.original_filename : file.original_filename
			temp_path = File.join(dirName,file_name)
			mutex.synchronize{
				File.open(temp_path, "wb") do |f|
					f.write(file.read)
				end				
			}			
		rescue 
			return nil
		end
		return temp_path
	else
		return nil
	end
end

def sendFile(file_name,displayName)    	
	io = File.open(file_name)
	io.binmode
	send_data(io.read,:filename => displayName,:disposition => 'attachment')
	io.close   		
end


require 'pathname'
# require 'rubygems'  
# require 'zip/zipfilesystem'  
gem 'rubyzip'  
require 'zip' 

def compress(source,target)
	begin
		Zip::File.open target, Zip::File::CREATE do |zip|  
			add_file_to_zip(source, zip,Pathname.new(source).basename)  
		end  
	rescue Zip::ZipEntryExistsError
		return
	end
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
