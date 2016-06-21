require 'roo'

def read_xlsx(fileName)
	# begin
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
		# xlsx.close
	# rescue Exception => e
	# 	return nil
	# end
	xlsx.close
	lines
end