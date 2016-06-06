module FileAccessor
  Tab="\t"
  New_Line="\n"

  def Read(fileName)
  	File.open(fileName,"r", :encoding => 'UTF-8') do |io|
      lines=[]
      io.readlines("\n").each do |line|
              array = line.chop!.split(Tab)             			 		     
              lines << array
      end
      lines
  	end
  end

  require 'win32ole'
  def self.ReadExcel(file_name)
  	excel = WIN32OLE.new("excel.application")
    workbook = excel.Workbooks.Open(file_name)    
	worksheet = workbook.Worksheets(1) 
	worksheet.Select
	row = worksheet.usedrange.rows.count
	column = worksheet.usedrange.columns.count
	lines=[]
	for i in 1..row do
		array = []
  		for j in 1..column do
    	array << worksheet.usedrange.cells(i,j).value.to_i
  		end 
  		lines << array
	end
	workbook.close
	excel.Quit
	lines
  end

  def Write(fileName, data)
  	return if !data

  	dirName=File.dirname(fileName)  	  
  	if(!File.directory?(dirName))
  		Dir.mkdir(File.dirname(fileName))
  	end

  	File.open(fileName, "w", :encoding => 'UTF-8') do |io|
  	  	data.each_with_index do |line,i|
  		  	io.write line.join(Tab)
          if i != data.count - 1            
            io.write(New_Line)
          end
  		end
  	end
  end 
  require 'pathname'
  def ConvertExcel(source,target)
    Write(target,ReadExcel(File.join(Pathname.new(File.dirname(__FILE__)).realpath,source)))
  end

  module_function :Read
  module_function :Write
  module_function :ConvertExcel
end