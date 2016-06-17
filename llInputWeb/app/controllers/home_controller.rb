class HomeController < ApplicationController
	$mutex_main_data = Mutex.new 
	$mutex_file = Mutex.new
	$main_data = []

	$guishudi_hash = {"1"=> "本地" ,"2"=>"外地","3"=>"本地外地"}
	$dengji_hash = {"1"=> "不限登记车" ,"2"=>"只限登记车","3"=>"所有车"}
	$leixing_hash =  {"1"=> "日期" ,"2"=>"星期","3"=>"日期单双","4"=>"休息日单双","5"=>"开四停四"}
	$yingwen_hash = {"0"=> "按0处理" ,"4"=>"按4处理","10"=>"末尾数字","11"=>"只限英文","-1"=>"不限英文"}
	$shijian_hash = {"1"=> "否" ,"2"=>"是"} 
	$truefalse_hash = {"0"=> "不限制" ,"1"=>"限制"} 
	$hash_array = [nil,nil,nil,nil,$guishudi_hash,$dengji_hash,$shijian_hash,$leixing_hash,$truefalse_hash,$truefalse_hash,$yingwen_hash,$truefalse_hash,nil,nil,nil,nil]
	DataArrayLength = 16  

	def main
		@data = []
		data = $main_data
		return nil if !data || data.length == 0         
		nd = []
		data.each do |row|
			nr = []
			row.each_with_index do |field,i|
				func_hash = $hash_array[i]
				if func_hash
					return nil if !func_hash.key?(field)
					nr << func_hash[field]
				else
					nr << field
				end
			end    
			nd << nr     
		end
		@data = nd
	end

	def resetByFile
	end  

	MainData = "MainData"
	Picture = "Picture"

	def resetByFileComplete
		unless request.get?
			file_input = params[:fileMain]
			return if !file_input
			if   readMainData(uploadFile(file_input,MainData,true))
				render  layout: "application" ,inline: "<p>#{file_input.original_filename} 上传成功</p>"
			else
				render  layout: "application" ,inline: "<p>#{file_input.original_filename} 上传失败</p>"
			end
		end
	end

	def edit
		id = params[:id]    
		item = search_by_id(id)
		if item
			@item = item
		else
			render html: "<strong>未找到该条限行，是不是另一个人正在删除它？</strong>".html_safe , layout: "application"
		end
	end

	protect_from_forgery :except => :edit_item  

   # you can disable csrf protection on controller-by-controller basis:  
   skip_before_filter :verify_authenticity_token    

   def edit_item
   	xuhao  =params[:xuhao]
   	item = search_by_id(xuhao)
   	if !item 
   		render html: "<strong>未找到该条限行，是不是另一个人正在删除它？</strong>".html_safe , layout: "application"
   		return
   	end

   	del =  params[:del]
   	if del
   		$mutex_main_data.synchronize{
   			$main_data.reject!{|itemT|itemT&&itemT.length>0&&itemT.first==xuhao}
   		}
   		render html: "<strong>序号: #{xuhao} 删除成功！</strong>".html_safe , layout: "application"
   	else
   		mesIndex = params[:mesIndex]
   		city_code = params[:city_code]
   		chepai = params[:chepai]
   		guishudi = params[:guishudi]
   		dengji = params[:dengji]
   		shijian = params[:shijian]
   		leixing = params[:leixing]
   		zhoumo = params[:zhoumo]
   		jiejiari = params[:jiejiari]
   		yingwen = params[:yingwen]
   		sanshiyi  = params[:sanshiyi]
   		xianhao = params[:xianhao]
   		time = params[:time]
   		date = params[:date]
   		quyu = params[:quyu]

   		fn = params[:fn]
   		if item[16]!=fn && fn && !fn.blank?
   			pic = params[:picture]
   			uploadFile(pic,Picture,false) if pic
   		end
   		fn = "" if !fn
   		$mutex_main_data.synchronize{
   			item.clear
   			item <<xuhao<< mesIndex << city_code<<chepai<<guishudi<<dengji<<shijian<<leixing<<zhoumo<<jiejiari<<yingwen<<sanshiyi<<xianhao<<time<<date<<quyu<<fn      
   		}
   		render html: "<strong>序号: #{xuhao} 提交成功！</strong>".html_safe , layout: "application"
   	end
   end

   def sendFile(file_name,displayName) 
   	$mutex_file.synchronize{   				
   		io = File.open(file_name)
   		io.binmode
   		send_data(io.read,:filename => displayName,:disposition => 'attachment')
   		io.close
   	}   			
   end

   def download
   	type = params[:file]
   	if type
   		dirName="#{Rails.root}/public/output"   		
   		if type=="main"
   			data = $main_data
   			if data && data.length>0
   				file_name = File.join(dirName,"outputMainData.txt") 
   				ensureDir(dirName)  
   				Write(file_name,data)	
   				sendFile(file_name,"限行规则导出.txt")
   				return
   			end		
   		elsif type =="picture"
   			sourceDir = File.join("public/input",Picture)
   			file_name = File.join(dirName,"pictures.zip")
   			ensureDir(dirName) 
   			if File.directory?(sourceDir)  
   				compress(sourceDir,file_name)
   				sendFile(file_name,"限行图片导出.zip")
   				return
   			end
   		end   		
   	end

   	render html: "<strong>没有可导出的数据</strong>".html_safe , layout: "application"      
   end

   private  
   def search_by_id(id)
   	return nil if !id 
   	if !id || id == "-1"
   		new_item = []
      # 新建一个
      $mutex_main_data.synchronize{
      	data = $main_data
      	data = [] if !data
      	maxId = (data.length == 0 ?  1 : (data.last.first.to_i + 1)).to_s
      	data << new_item
      	$main_data = data

      	new_item << maxId << "0" << "110000" << ""<< "1" << "3" << "1" <<"1"<<"0"<<"0"<<"0"<<"0"<<""<<""<<""<<""<<""
      }     
      return new_item
  else            
  	data = $main_data  
  	item = data.select{|i|i&&i.length>0&&i[0]&&i[0]==id}
  	if item&&item.length>0
  		return item[0]
  	else
  		return nil
  	end
  end       
end

def convertUI(data)
	return nil if !data
	result = []
	data.each_with_index do |line,i|
		return nil if !line
		if  line.length == DataArrayLength+1
		elsif line.length != DataArrayLength
			return nil
		else 
			line << ""
		end
		result << line
	end
	result
end

def readMainData(temp_path)
	return nil if !temp_path 
	begin
		data = []
		$mutex_file.synchronize{				
			data = Read(temp_path)			
			data_for_view = convertUI(data)
			return nil if !data_for_view || data_for_view.length == 0 
			data_for_view.shift
			$main_data = data_for_view		
		}
		return data
	rescue 
		return nil
	end
end

def uploadFile(file,dirN,bAddIp)
	if !file.original_filename.empty?

		dirName="#{Rails.root}/public/input" 
		ensureDir(dirName)
		if dirN
			dirName = File.join(dirName,dirN)
			ensureDir(dirName)
		end
		begin
			file_name = bAddIp ? request.remote_ip()+file.original_filename : file.original_filename
			temp_path = File.join(dirName,file_name)
			$mutex_file.synchronize{
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

require 'rubygems'  
require 'zip/zipfilesystem'  
def compress(source,target)
	begin
		Zip::ZipFile.open target, Zip::ZipFile::CREATE do |zip|  
			Dir.foreach(source) do |sub_file_name|  
				tar = "#{source}/#{sub_file_name}"
				zip.add(sub_file_name,tar) unless sub_file_name == '.' or sub_file_name == '..' 
			end  

		# add_file_to_zip(source, zip)  
	end  
  rescue Zip::ZipEntryExistsError
	return
  end
end  

def add_file_to_zip(file_path, zip)  
	if File.directory?(file_path)  
		Dir.foreach(file_path) do |sub_file_name|  
			add_file_to_zip("#{file_path}/#{sub_file_name}", zip) unless sub_file_name == '.' or sub_file_name == '..'  
		end  
	else  
		zip.add(file_path, file_path)  
	end  
end  
end