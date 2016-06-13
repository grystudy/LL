class HomeController < ApplicationController
  def index
  end

  $main_data = []
  def main
  end
  
  def resetByFile
  end  
  
  def resetByFileComplete
    unless request.get?
      file_input = params[:fileMain]
      return if !file_input
      if uploadFile(file_input)
        render  layout: "application" ,inline: "<p>#{file_input.original_filename} 上传成功</p>"
      else
        render  layout: "application" ,inline: "<p>#{file_input.original_filename} 上传失败</p>"
      end
    end
  end
  
  private  

  def convertUI(data)
    return nil if !data
    result = []
    data.each_with_index do |line,i|
      return nil if !line || line.length!=16
      result << convertLine(line)
    end

    result
  end

  def convertLine(line)
    line
  end

  def uploadFile(file)
   if !file.original_filename.empty?

    dirName="#{Rails.root}/public/input" 

    if(!File.directory?(dirName))
      Dir.mkdir(dirName)
    end

    begin
      temp_path = File.join(dirName,request.remote_ip()+"_inputMainDataTemp.txt")
      File.open(temp_path, "wb") do |f|
        f.write(file.read)
      end
      data = Read(temp_path)
      data_for_view = convertUI(data)
      return nil if !data_for_view
      $main_data = data_for_view
    rescue 
      return nil
    end

    return nil if !data
    Write(File.join(dirName,"inputMainData.txt"),data)

    return data
  else
   return nil
 end
end

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

end
