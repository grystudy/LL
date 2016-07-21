require 'spreadsheet'
def write_xlsx(fileName, data)
	return false if !data

	dirName=File.dirname(fileName)      
	
	book = Spreadsheet::Workbook.new
	sheet1 = book.create_worksheet
	#行从一开始，列头
	data.each_with_index do |line,i|
		line.each_with_index do |col,col_i|
			sheet1[i+1,col_i]=col
		end
	end
	book.write fileName
	true
end

def output(key_,value_)
	data_to_excel = []
	value_.each do |item_wrap_|
		puts "边个数不是1+#{item_wrap_.admcode} + #{item_wrap_.geom.length}" if item_wrap_.geom.length != 1
		array_t = item_wrap_.geom[0].map { |e| [e.x,e.y] }			
		array_append = []
		array_append << item_wrap_.info_id
		item_wrap_.info_wrap_array.each_with_index do |info_wrap_,ii_|
			array_append << ii_
			array_append << info_wrap_.is_restrict ? "限" : "不限"
			array_append << info_wrap_.geom_type
		end
		array_t[0].concat(array_append)			
		data_to_excel.concat array_t
	end

	fileName = File.join("areaRes","#{key_}.xls")
	dirName=File.dirname(fileName)  	  
	if(!File.directory?(dirName))
		Dir.mkdir(File.dirname(fileName))
	end
	write_xlsx(fileName,data_to_excel)

	fileName = File.join("areaRes/json","#{key_}.txt")
	dirName=File.dirname(fileName)  	  
	if(!File.directory?(dirName))
		Dir.mkdir(File.dirname(fileName))
	end
	File.open(fileName, "w", :encoding => 'UTF-8') do |io|
		res_str = value_.to_json.delete "\\"
		io.write res_str
	end
end

require File.join(File.dirname(__FILE__),"llShpReader.rb")
return unless @read_result

hash_issingle_to_data_array = @read_result.map do |e|  
	e.to_a.group_by do |ele_|
		ele_.first.split(';').length>1
	end
end

hash_issingle_to_data_array.each do |item_|
	single_array = item_.fetch false,[]
	multi_array = item_.fetch true,[]
	
	single_array.each do |e_|
		key = e_.first
		value = e_.last

		contains_id_array = multi_array.select do |multi_e_|
			keys = multi_e_.first.split(';')

			if keys.reject!{|temp_| temp_ == key}
				puts "有重复的合并  #{key}"
				value.concat multi_e_.last 
				multi_e_[0] = keys.join(";")
			end
		end

		output key,value
	end

	multi_array.each do |e_|
		output e_.first,e_.last
	end
end