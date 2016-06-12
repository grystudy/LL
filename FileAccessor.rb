module FileAccessor
  Tab="\t"
  New_Line="\n"

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
    	array << worksheet.usedrange.cells(i,j).Text.to_s.delete("\n").delete("\"")
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

  def CalcDataPath
    dataPath = "LLData"
    maxIntT = 0
    Dir.entries(File.dirname(__FILE__)).each do |dirNameT|
      if File.file?(dirNameT)
        next
      end 
      if /^#{dataPath}(\d{6,8})$/i =~ dirNameT  
      intT= $1.to_i
        maxIntT = maxIntT > intT ? maxIntT : intT;
      end
    end
    dataPath += maxIntT.to_s
    dataPath
  end
  module_function :CalcDataPath
end

InputHoliday = "inputHoliday.txt"
InputMainData = "inputMainData.txt"