class HomeController < ApplicationController
  def index
  end
  
  def resetByFile
  end  
  
  def resetByFileComplete
    unless request.get?
      if filename=uploadFile(params[:file]['file'])
        render :text=>filename
      end
    end
  end
  
  def uploadFile(file)
   if !file.original_filename.empty?
     filename=getFileName(file.original_filename)

     dirName="#{Rails.root}/public/input" 
     if(!File.directory?(dirName))
      Dir.mkdir(dirName)
    end

    File.open(File.join(dirName,filename), "wb") do |f|
     f.write(file.read)
   end
   return filename
 end
end

def getFileName(filename)
	if !filename.nil?
   return filename
 end
end
end
