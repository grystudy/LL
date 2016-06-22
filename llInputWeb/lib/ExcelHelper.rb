require 'roo'

def read_xlsx(fileName)
	xlsx = Roo::Spreadsheet.open(fileName)
	lines=[]
	xlsx.sheet(0).each_row_streaming do |row|
		row_array = []
		row.each do |column|
			col_value =  column.value.to_s
			row_array << col_value ? col_value : ""
		end
		lines << row_array
	end
	xlsx.close
	lines
end

def write_xlsx(fileName, data)
	return false if !data

	dirName=File.dirname(fileName)      
	ensureDir(dirName)
    xlsx = Roo::Spreadsheet.open(fileName)
	#行从一开始，列头
		data.each_with_index do |line,i|
			line.each_with_index do |col,col_i|
				xlsx.set(i+1 , col_i , col)
			end
		end
	xlsx.close
	true
end