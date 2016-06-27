class EventllController < ApplicationController
	@@mutex_main_data = Mutex.new 
	@@mutex_file = Mutex.new
	@@main_data = []

	DataArrayLength = 10  

	def main
		@data = []
		data = @@main_data
		return nil if !data || data.length == 0         
		nd = []
		data.each do |row|
			nr = []
			row.each_with_index do |field,i|				
				nr << field
			end    
			nd << nr     
		end
		@data = nd

      @xuhao = params[:xuhao]
	end

	def resetByFile
	end  

	MainData = "MainData"

	def import
		unless request.get?
			file_input = params[:fileMain]
			return if !file_input
			main_data = try_save_and_parse_data(file_input,MainData,request.remote_ip(),@@mutex_file,DataArrayLength)
			if  main_data
				@@mutex_main_data.synchronize{
					@@main_data = main_data
				}
				render  layout: "application" ,inline: "<p>#{file_input.original_filename} 上传成功</p><%= link_to \"查看\",:action => \"main\" %>"
			else
				render  layout: "application" ,inline: "<p>#{file_input.original_filename} 上传失败</p>"
			end
		end
	end

	def edit
		id = params[:id]    
		item = create_or_search(id:id, main_data:@@main_data, data_mutex:@@mutex_main_data){|new_item,maxId|new_item << maxId << "110000" << "北京市"<< "" << "" << "" <<""<<""<<""<<""}
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
   	item = create_or_search(id:xuhao, main_data:@@main_data, data_mutex:@@mutex_main_data)
   	if !item 
   		render html: "<strong>未找到该条限行，是不是另一个人正在删除它？</strong>".html_safe , layout: "application"
   		return
   	end

   	del =  params[:del]
   	if del
   		@@mutex_main_data.synchronize{
   			@@main_data.reject!{|itemT|itemT&&itemT.length>0&&itemT.first==xuhao}
   		}
   		render inline: "<strong>序号: #{xuhao} 删除成功！</strong><%= link_to \"查看\",:action => \"main\" %>".html_safe , layout: "application"
   	else
   		city_code = params[:city_code]
   		city = params[:city]
   		title = params[:title]
   		time = params[:time]
   		etime = params[:etime]
   		area = params[:area]
   		restriction = params[:restriction]
   		detail = params[:detail]
   		link = params[:link]

   		@@mutex_main_data.synchronize{
   			item.clear
   			item <<xuhao<< city_code << city<<title<<time<<etime<<area<<restriction<<detail<<link     
   		}
   		render inline: "<strong>序号: #{xuhao} 提交成功！</strong>　<%= link_to \"查看\",:action => \"main\", :xuhao=> #{xuhao}%>".html_safe , layout: "application"
   	end
   end

   def download
   	type = params[:file]
   	if type
   		dirName="#{Rails.root}/public/output"   		
   		if type=="event"
   			data = @@main_data
   			if data && data.length>0
   				file_name =  File.join(dirName,"outputEventData.xls")
   				File.delete(file_name) if File.exist?(file_name)	
   				@@mutex_file.synchronize{  
   					ensureDir(dirName)
   					if write_xlsx(file_name,data)   
   						sendFile(file_name,"事件限行导出.xls")		
   					else
   						file_name =  File.join(dirName,"outputEventData.txt")
   						File.delete(file_name) if File.exist?(file_name)	
   						if Write(file_name,data)
   							sendFile(file_name,"事件限行导出.txt")	
   						end
   					end
   				}
   				return
   			end 		  		
   		end

   		render html: "<strong>没有可导出的数据</strong>".html_safe , layout: "application"      
   	end
   end

   private    
   require 'FileHelper.rb'
end
