module FileAccessor
  Tab="\t"
  New_Line="\n"

  def Read(fileName)
  	File.open(fileName,"r", :encoding => "UTF-8") do |io|		
      lines=[]
      io.each do |line|
              array = line.chop!.split(Tab)             			 		     
              lines << array
      end
      lines
  	end
  end

  def Write(fileName, data)
  	dirName=File.dirname(fileName)  	  
  	if(!File.directory?(dirName))
  		Dir.mkdir(File.dirname(fileName))
  	end

  	File.open(fileName, "w", :encoding => "UTF-8") do |io|
  	  	data.each_with_index do |line,i|
  		  	io.write line.join(Tab)
          if i != data.count - 1            
            io.write(New_Line)
          end
  		end
  	end
  end 
  module_function :Read
  module_function :Write
end

class CityLLInfoWrap  
  attr_accessor :dicDateToData 
  attr_accessor :lstArea
  attr_accessor :lstLimitInfo
  def initialize()
    @dicDateToData = Hash.new
    @lstArea = Array.new
    @lstLimitInfo = []
  end
end

require "date"

convertDateTime = lambda do |strDate|
	year = strDate[0,4].force_encoding("UTF-8")
	month = strDate[4,2]
	day = strDate[6,2]	
	return Date.new(year.to_i,month.to_i,day.to_i)
end

judgeIsWeekend = lambda do |str|
  [6,0].include?(convertDateTime.call(str).wday)
end

Path="限行"

# 读节假日
inputHoliday = FileAccessor.Read(File.join(Path,"inputHoliday.txt"))
inputHoliday[0][0].delete!("\uFEFF")

lstWorkWeekend = []
lstRestWorkday = []
inputHoliday.each do |dateArray|
  (judgeIsWeekend.call(dateArray.first) ? lstWorkWeekend : lstRestWorkday)
  .push(dateArray.first)
end

# 工作日类型
Workday = 0;
Weekend = 1;
WorkWeekend = 2;
RestWorkday = 3;

judgeWorkdayType = lambda do |str|
  if(judgeIsWeekend.call(str))
    lstWorkWeekend.include?(str) ? WorkWeekend : Weekend
  else
    lstRestWorkday.include?(str) ? RestWorkday : Workday
  end
end

# 读主数据
inputMainData = FileAccessor.Read(File.join(Path,"inputMainData.txt"))
inputMainData.delete_at(0)
puts inputMainData.count
dicCityCodeTo_DateToData = Hash.new
allAreaCount = 0
llCount = 0

getAreaId = lambda do |cityCodeP,indexP|
  (cityCodeP * 100 + indexP).to_s    
end

# 各字段
inputMainData.each_with_index do |item,indexInMainData|
 mesIndex = item[1];
 cityCode = item[2];
 chepaihao = item[3];
 bendiwaidiType = item[4];
 waidiRegisterType = item[5];
 rType = item[6];
 isWorkWeekendR = item[7] == "1";
 isHolidayR = item[8] == "1";
 englishR = item[9];
 isThirtyoneR = item[10] == "1";
 rNumber = item[11];
 timeRange = item[12];
 dateRange = item[13];
 strArea = item[14];

 isRTRiqi = rType == "1";
 isRTXingqi = rType == "2";
 isRTRiqiDanshuang = rType == "3"; # 按车牌尾号分单双日通行，车牌尾号最后一位阿拉伯数字为1、3、5、7、9的车辆只准许单日通行；车牌尾号最后一位阿拉伯数字为0、2、4、6、8的车辆只准许双日通行
 isRTXiuxiriDanShuang = rType == "4"; # 杭州
 isRTRun4Pause4 = rType == "5"; # 贵阳

 # danhaoR = "0,2,4,6,8"
 # shuanghaoR = "1,3,5,7,9"
 danhaoR = "双号"
 shuanghaoR = "单号"
 lstRNumEveryDay = nil
 # 根据格式处理号牌列表
 if(rNumber && rNumber.empty? == false)
  rNumSplitted = rNumber.split(';')
  case rNumSplitted.count
    when 1
      rNumSplitted = rNumSplitted.first.split(',');
      if (rNumSplitted.count == 10 && isRTRiqi)                            
        lstRNumEveryDay = rNumSplitted;
      end
    when 5
      if (isRTRiqi)
        lstRNumEveryDay = []
        # 兰州极特殊 1,6;2,7;3,8;4,9;5,0 车牌尾号为l、6的机动车，每月1日、6日、11日、16日、21日、26日、31日限行
        rNumSplitted.each do |t|   
          (1..10).each do |i|  
            c = i == 10 ? 0 : i
            if (t.include?(c.to_s))
              lstRNumEveryDay << t;
            end
          end
        end

        if (lstRNumEveryDay.count != 10)
          next
        end                         
      elsif (isRTXingqi)                           
        lstRNumEveryDay = rNumSplitted;
      end
  end 
 end

  # 日期范围
  startDateStr = nil
  endDateStr = nil;

  if(dateRange && dateRange.empty? == false)
    arrayT = dateRange.split('-')
    if(arrayT.length == 2)
     startDateStr,endDateStr = arrayT[0],arrayT[1]
    end
  else
    dateRange = "无日期范围"
  end               

  if ( !startDateStr || !endDateStr)    
    startDateStr = "20160101";
    endDateStr = "20170101";         
  end
  startDate = convertDateTime.call(startDateStr);
  endDate = convertDateTime.call(endDateStr);

  cityLL = nil
  if(dicCityCodeTo_DateToData.key?(cityCode))
    cityLL = dicCityCodeTo_DateToData[cityCode]
  else
    cityLL = CityLLInfoWrap.new
    dicCityCodeTo_DateToData.store(cityCode,cityLL)
  end

  areaIndex = nil
  if(strArea && strArea.empty? == false)
    strArea = strArea.delete("。").delete("\n").delete("\r")
    areaIndex = cityLL.lstArea.find_index(strArea)
    if(!areaIndex)
      areaIndex = cityLL.lstArea.count
      cityLL.lstArea << strArea
      allAreaCount = allAreaCount + 1
    end
  end

  # 一周限行信息
  weekRtInfo = Array.new(7)

  # 遍历每一天
  while true
    if startDate > endDate
      break
    end
    strDateCur = startDate.strftime("%Y%m%d")
    curDay = startDate.day
    curWDay = startDate.wday
    startDate = startDate + 1

    lstLL = nil 
    if !cityLL.dicDateToData.key?(strDateCur)
      lstLL = []
      cityLL.dicDateToData.store(strDateCur,lstLL)
    else
      lstLL = cityLL.dicDateToData[strDateCur]
    end
    
    # 开始做限行item
    # 判断这天是否限制    
    canIgnore = false

    case judgeWorkdayType.call(strDateCur)
    when Workday
      if isRTXiuxiriDanShuang
        canIgnore = true
      end
    when WorkWeekend
      if !isWorkWeekendR
        canIgnore = true
      end
    when RestWorkday
      if !isHolidayR
        canIgnore = true
      end
    when Weekend
      if !isHolidayR
        canIgnore = true
      end
    end

    if(!isThirtyoneR && curDay == 31)
      canIgnore = true
    end

    # 取限制什么号
    rNumberCurDay = "所有号牌"
    if isRTRiqi
      if(lstRNumEveryDay)
        t = curDay % 10
        t = t==0 ? 10 : t

        rNumberCurDay = lstRNumEveryDay[t-1]
      end
    elsif isRTXingqi
      if lstRNumEveryDay
        t = curWDay % 7
        if [0,6].include?(t)
          canIgnore = true
        end

        rNumberCurDay = lstRNumEveryDay[t-1]
      end
    elsif isRTRiqiDanshuang || isRTXiuxiriDanShuang
      t = curDay % 2
      rNumberCurDay = t == 0 ? shuanghaoR : danhaoR
    elsif isRTRun4Pause4
      rNumberCurDay = "开四停四"
    end

    if(rNumberCurDay == "-1")
      canIgnore = true # -1表示不限号
    end

    if canIgnore
      rNumberCurDay = "不限号"
    end

    if(!weekRtInfo[curWDay])
      weekRtInfo[curWDay] = rNumberCurDay
    end

    llItem = []
    llItem << 0
    llItem << cityCode
    llItem << strDateCur
    llItem << bendiwaidiType
    llItem << waidiRegisterType
    llItem << rType
    llItem << (isWorkWeekendR ? "1" : "0")
    llItem << (isThirtyoneR ? "1" : "0")
    llItem << (isHolidayR ? "1" : "0")
    llItem << timeRange
    llItem << rNumberCurDay
    llItem << englishR
    llItem << getAreaId.call(cityCode.to_i,areaIndex)
    llItem << mesIndex

    # 数据库需要两列时间?
    llItem << strDateCur
    llItem << strDateCur

    # 在对应哪条输入数据（索引0起）
    llItem << indexInMainData
   
    lstLL << llItem
    llCount = llCount + 1
  end

  arrayTemp = []
  arrayTemp << indexInMainData
  arrayTemp << dateRange
  arrayTemp << weekRtInfo.join(";")
  cityLL.lstLimitInfo << arrayTemp
end

# 写区域数据
resultT = []
resultT << ["id", "city_code", "area"]
  
dicCityCodeTo_DateToData.each do |keyP,valueP|
  valueP.lstArea.each_with_index do |eleP,iP|
    newArrayT=[]
    newArrayT << getAreaId.call(keyP.to_i,iP)
    newArrayT << keyP
    newArrayT << eleP
    resultT << newArrayT
  end
end
outputPath = File.join(Path,"rbout")
FileAccessor.Write(File.join(outputPath,"区域表.txt"),resultT)

# 写主数据
resultT = []
resultT << %w(id city_code date license_attri register type date_off_r thirty_one_r holiday_r time number english_number area_id msg_id create_at update_at limit_Info_Id)
dicCityCodeTo_DateToData.each do |keyP,valueP|
  valueP.dicDateToData.each_value do |value|
    value.each do |ele|
      resultT << ele  
    end
  end
end
FileAccessor.Write(File.join(outputPath,"主数据.txt"),resultT)

# 写主数据关联数据
resultT = []
resultT << %w(id date_range week_rt_info)
dicCityCodeTo_DateToData.each do |keyP,valueP|
  valueP.lstLimitInfo.each do |value|   
    resultT << value
  end
end
FileAccessor.Write(File.join(outputPath,"关联数据.txt"),resultT)