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

require File.join(File.dirname(__FILE__),"llShpReader.rb")

data_to_excel = []
@read_result.each do |hash_|
	hash_.each do |key_,value_|
		data_to_excel.clear
		value_.each_with_index do |item_wrap_,i_|
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

		fileName = File.join("areaRes","#{key_}.xlsx")
		dirName=File.dirname(fileName)  	  
		if(!File.directory?(dirName))
			Dir.mkdir(File.dirname(fileName))
		end
		write_xlsx(fileName,data_to_excel)
	end
end