module InputPretreament
  DataPath = "LLData"
  InputHoliday = "inputHoliday.txt"
  InputMainData = "inputMainData.txt"

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