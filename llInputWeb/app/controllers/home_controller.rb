

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
 
	def import
		unless request.get?
			file_input = params[:fileMain]
			return if !file_input
			main_data = try_save_and_parse_data(file_input,MainData,request.remote_ip(),$mutex_file,DataArrayLength)
			if  main_data
				$mutex_main_data.synchronize{
					$main_data = main_data
				}
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
   			uploadFile(pic,Picture,nil,$mutex_file) if pic
   		end
   		fn = "" if !fn
   		$mutex_main_data.synchronize{
   			item.clear
   			item <<xuhao<< mesIndex << city_code<<chepai<<guishudi<<dengji<<shijian<<leixing<<zhoumo<<jiejiari<<yingwen<<sanshiyi<<xianhao<<time<<date<<quyu<<fn      
   		}
   		render html: "<strong>序号: #{xuhao} 提交成功！</strong>".html_safe , layout: "application"
   	end
   end

   def download
   	type = params[:file]
   	if type
   		dirName="#{Rails.root}/public/output"   		
   		if type=="main"
   			data = $main_data
   			if data && data.length>0
   				file_name = File.join(dirName,"outputMainData.txt") 
   				$mutex_file.synchronize{  
   					ensureDir(dirName)   	
   					Write(file_name,data)
   					sendFile(file_name,"限行规则导出.txt")	
   				}
   				return
   			end		
   		elsif type =="picture"
   			sourceDir = File.join("public/input",Picture)
   			file_name = File.join(dirName,"pictures.zip")
   			if File.directory?(sourceDir)  
   				$mutex_file.synchronize{   
   					ensureDir(dirName) 
   					File.delete(file_name) if File.exist?(file_name)	
   					compress(sourceDir,file_name)
   					sendFile(file_name,"限行图片导出.zip")
   				}
   				return
   			end
   		end   		
   	end

   	render html: "<strong>没有可导出的数据</strong>".html_safe , layout: "application"      
   end

   private    
   require 'FileHelper.rb'
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
end

