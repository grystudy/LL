require File.join(File.dirname(__FILE__),"FileAccessor.rb")

dataPath = FileAccessor.CalcDataPath

# 输入文件转换
holiday_file_name = File.join(dataPath,InputHoliday)
main_data_file_name = File.join(dataPath,InputMainData)
detail_file_name = File.join(dataPath,"inputDetail.txt")

if !File.exist?(holiday_file_name)
  excel_file_name = File.join(dataPath,"2016年节假日数据.xlsx")
  if !File.exist?(excel_file_name)
    puts "没有输入文件!"
    return 
  end

  FileAccessor.ConvertExcel(excel_file_name,holiday_file_name)
end

if !File.exist?(main_data_file_name)
  excel_file_name = File.join(dataPath,"限行规则数据.xlsx")
  if !File.exist?(excel_file_name)
    puts "没有输入文件!"
    return 
  end

  FileAccessor.ConvertExcel(excel_file_name,main_data_file_name)
end

if !File.exist?(detail_file_name)
  excel_file_name = File.join(dataPath,"限行描述数据.xlsx")
  if !File.exist?(excel_file_name)
    puts "没有输入文件!"
    return 
  end

  FileAccessor.ConvertExcel(excel_file_name,detail_file_name)
end