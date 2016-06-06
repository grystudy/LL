using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

namespace ConsoleApplication1
{
    class Program
    {
        const string TAB = "\t";
        const string NEW_LINE = "\r\n";
        static List<string[]> Read(string fileName)
        {
            try
            {
                if (string.IsNullOrEmpty(fileName)) return null;
                using (var file = File.Open(fileName, FileMode.Open, FileAccess.Read))
                {
                    using (var streamReader = new StreamReader(file, Encoding.UTF8))
                    {
                        var strInFile = streamReader.ReadToEnd();
                        var splitChar = ChooseSplitChar(strInFile);
                        var strData = strInFile.Replace(NEW_LINE, splitChar.ToString());
                        strData = strData.Replace("\"", string.Empty);
                        if (string.IsNullOrEmpty(strData)) return null;
                        var rows = strData.Split(splitChar);
                        if (rows == null || rows.Length == 0) return null;

                        var result = new List<string[]>();
                        for (int rowI = 0; rowI < rows.Length; rowI++)
                        {
                            var rowData = rows[rowI];
                            if (string.IsNullOrEmpty(rowData)) continue;
                            var values = rowData.Split('\t');
                            if (values == null || values.Length == 0) return null;
                            result.Add(values);
                        }

                        return result;
                    }
                }
            }
            catch
            {
                return null;
            }
        }

        static void Write(string fileName, string[][] data)
        {
            var path = Path.GetDirectoryName(fileName);
            if (Directory.Exists(path) == false) Directory.CreateDirectory(path);
            using (var file = File.Create(fileName))
            {
                using (var writer = new StreamWriter(file, Encoding.UTF8))
                {
                    for (int lineI = 0; lineI < data.Length; lineI++)
                    {
                        var line = data[lineI];
                        writer.Write(string.Join(TAB, line));
                        if (lineI != data.Length - 1)
                        {
                            writer.Write(NEW_LINE);
                        }
                    }
                }
            }
        }

        public static char[] s_specialChars = new char[] { '×', 'œ', 'Ÿ', 'ž', '@' };
        public static char ChooseSplitChar(string source)
        {
            char res = s_specialChars[0];
            if (string.IsNullOrEmpty(source)) return res;
            foreach (var c in s_specialChars)
            {
                if (source.Contains(c) == false) return c;
            }
            return res;
        }

        class cityLLInfo
        {
            public Dictionary<string, List<LLItem>> dicDateToData = new Dictionary<string, List<LLItem>>();
            public List<string> lstArea = new List<string>();
        }

        /// <summary>
        /// 日期个数问题，2014年的录了还导数据吗
        /// 北京 3 4 rtype为什么不一样 2没有对应,有的rt =2 按星期了 number为空全限 为什么rt不设为1
        /// 知道单双号了就不用存13579了
        /// Register 大部分是3，应该是 0就好了
        /// excel数据里有的还有引号
        /// 输入区域的标点符号不规范啊！！！不抽区域id的结果！！！
        /// </summary>
        /// <param name="args"></param>
        static void Main(string[] args)
        {
            var path = @"..\..\..\..\..\LLData201605";
            #region 读详细信息去掉其中的\n并重写
            var inputDetail = Read(Path.Combine(path, @"inputDetail.txt"));
            // 小心\n
            foreach (var temp in inputDetail)
            {
                for (int iTemp = 0; iTemp < temp.Length; iTemp++)
                {
                    temp[iTemp] = temp[iTemp].Replace("\n", string.Empty);
                }
            }
            Write(Path.Combine(path, @"inputDetail.txt"), inputDetail.ToArray());
            inputDetail.RemoveAt(0);
            Dictionary<string, string> dicIdToDetail = new Dictionary<string, string>();
            foreach (var item in inputDetail)
            {
                if (dicIdToDetail.ContainsKey(item[0])) continue;
                dicIdToDetail.Add(item[0], item[2]);
            }
            #endregion

            #region 读节假日
            Func<string, DateTime> convertDateTime = (strDate) =>
              {
                  var year = strDate.Substring(0, 4);
                  var month = strDate.Substring(4, 2);
                  var day = strDate.Substring(6, 2);
                  return new DateTime(Convert.ToInt32(year), Convert.ToInt32(month), Convert.ToInt32(day));
              };
            // 读取节假日数据
            var inputHoliday = Read(Path.Combine(path, @"inputHoliday.txt"));
            var lstWorkWeekEnd = new List<DateTime>();
            var lstRestWorkday = new List<DateTime>();
            foreach (var item in inputHoliday)
            {
                var dateT = convertDateTime(item.First());
                if (dateT.DayOfWeek == DayOfWeek.Saturday || dateT.DayOfWeek == DayOfWeek.Sunday)
                {
                    lstWorkWeekEnd.Add(dateT);
                }
                else
                {
                    lstRestWorkday.Add(dateT);
                }
            }

            #region 工作日类型
            const byte Workday = 0;
            const byte Weekend = 1;
            const byte WorkWeekend = 2;
            const byte RestWorkday = 3;

            Func<DateTime, byte> judgeWorkdayType = (dateT) =>
            {
                if (dateT.DayOfWeek == DayOfWeek.Saturday || dateT.DayOfWeek == DayOfWeek.Sunday)
                {
                    return lstWorkWeekEnd.Contains(dateT) ? WorkWeekend : Weekend;
                }
                else
                {
                    return lstRestWorkday.Contains(dateT) ? RestWorkday : Workday;
                }
            };
            #endregion
            #endregion

            #region 读主数据
            var input = Read(Path.Combine(path, @"inputMainData.txt"));
            // 小心\n
            foreach (var temp in input)
            {
                for (int iTemp = 0; iTemp < temp.Length; iTemp++)
                {
                    temp[iTemp] = temp[iTemp].Replace("\n", string.Empty);
                }
            }
            Write(Path.Combine(path, @"inputMainData.txt"), input.ToArray());

            input.RemoveAt(0);

            const string dateFormate = "yyyyMMdd";
            Func<int, int, int> getAreaId = (cityCodeT, indexT) => { return cityCodeT * 100 + indexT; };

            var dicCityCodeTo_DateToData = new Dictionary<int, cityLLInfo>();
            int allAreaCount = 0;
            int llCount = 0;
            foreach (var item in input)
            {
                #region 各字段
                var mesIndex = item[1];
                var cityCode = Convert.ToInt32(item[2]);
                var chepaihao = item[3];
                var bendiwaidiType = item[4];
                var waidiRegisterType = item[5];
                var rType = item[6];
                var isWorkWeekendR = item[7] == "1";
                var isHolidayR = item[8] == "1";
                var englishR = item[9];
                var isThirtyoneR = item[10] == "1";
                var rNumber = item[11];
                var timeRange = item[12];
                var dateRange = item[13];
                var strArea = item[14];

                var isRTRiqi = rType == "1";
                var isRTXingqi = rType == "2";
                var isRTRiqiDanshuang = rType == "3"; // 按车牌尾号分单双日通行，车牌尾号最后一位阿拉伯数字为1、3、5、7、9的车辆只准许单日通行；车牌尾号最后一位阿拉伯数字为0、2、4、6、8的车辆只准许双日通行
                var isRTXiuxiriDanShuang = rType == "4"; // 杭州
                var isRTRun4Pause4 = rType == "5"; // 贵阳

                const string danhaoR = "0,2,4,6,8";
                const string shuanghaoR = "1,3,5,7,9";

                List<string> lstRNumEveryDay = null;
                if (string.IsNullOrEmpty(rNumber) == false)
                {
                    var splittedT = rNumber.Split(';');
                    if (splittedT.Length == 5 || splittedT.Length == 1)
                    {
                        if (splittedT.Length == 5)
                        {
                            if (isRTRiqi)
                            {
                                lstRNumEveryDay = new List<string>();
                                // 兰州极特殊 1,6;2,7;3,8;4,9;5,0 车牌尾号为l、6的机动车，每月1日、6日、11日、16日、21日、26日、31日限行
                                foreach (var t in splittedT)
                                {
                                    for (int i = 1; i <= 10; i++)
                                    {
                                        var c = i == 10 ? 0 : i;
                                        if (t.Contains(c.ToString()))
                                        {
                                            lstRNumEveryDay.Add(t);
                                        }
                                    }
                                }

                                if (lstRNumEveryDay.Count != 10) continue;
                            }
                            else if (isRTXingqi)
                            {
                                lstRNumEveryDay = new List<string>(splittedT);
                            }
                        }
                        else if (splittedT.Length == 1)
                        {
                            splittedT = splittedT.First().Split(',');
                            if (splittedT.Length == 10 && isRTRiqi)
                            {
                                lstRNumEveryDay = new List<string>(splittedT);
                            }
                        }
                    }
                }
                #endregion

                #region 日期范围
                string startDateStr = null, endDateStr = null;
                if (!string.IsNullOrEmpty(dateRange))
                {
                    var sT = dateRange.Split('-');
                    if (sT.Length == 2)
                    {
                        startDateStr = sT[0];
                        endDateStr = sT[1];
                    }
                }
                if (startDateStr == null || endDateStr == null)
                {
                    startDateStr = "20160101";
                    endDateStr = "20170101";
                }

                var startDate = convertDateTime(startDateStr);
                var endDate = convertDateTime(endDateStr);
                #endregion

                cityLLInfo cityLL = null;
                if (!dicCityCodeTo_DateToData.TryGetValue(cityCode, out cityLL))
                {
                    cityLL = new cityLLInfo();
                    dicCityCodeTo_DateToData.Add(cityCode, cityLL);
                }

                var areaIndex = -1;
                if (!string.IsNullOrEmpty(strArea))
                {
                    strArea = strArea.Replace("。", string.Empty);
                    strArea = strArea.Replace("\n", string.Empty);
                    strArea = strArea.Replace("\r", string.Empty);
                    areaIndex = cityLL.lstArea.IndexOf(strArea);
                    if (areaIndex < 0)
                    {
                        areaIndex = cityLL.lstArea.Count;
                        cityLL.lstArea.Add(strArea);
                        allAreaCount++;
                    }
                }

                // 遍历每一天
                while (true)
                {
                    if (startDate > endDate) break;
                    var strDateCur = startDate.ToString(dateFormate);
                    var dateCur = startDate;
                    startDate = startDate.AddDays(1);

                    List<LLItem> lstLL = null;
                    if (!cityLL.dicDateToData.TryGetValue(strDateCur, out lstLL))
                    {
                        lstLL = new List<LLItem>();
                        cityLL.dicDateToData.Add(strDateCur, lstLL);
                    }

                    // 开始做限行item
                    #region 判断这天是否限制
                    switch (judgeWorkdayType(dateCur))
                    {
                        case Workday:
                            if (isRTXiuxiriDanShuang) continue;
                            break;
                        case WorkWeekend:
                            if (isWorkWeekendR == false) continue;
                            //if (isRTXiuxiriDanShuang) continue;
                            break;
                        case RestWorkday:
                            if (isHolidayR == false) continue;
                            break;
                        case Weekend:
                            if (isHolidayR == false) continue;
                            break;
                        default:
                            continue;
                    }

                    if (!isThirtyoneR && dateCur.Day == 31)
                    {
                        continue;
                    }
                    #endregion

                    #region 取限制什么号
                    string rNumberCurDay = string.Empty;
                    if (isRTRiqi)
                    {
                        if (lstRNumEveryDay == null) rNumberCurDay = "所有号牌";
                        else
                        {
                            var t = dateCur.Day % 10;
                            if (t == 0) t = 10;

                            rNumberCurDay = lstRNumEveryDay[t - 1];
                            if (rNumberCurDay == "-1") continue; // "不限号";
                        }
                    }
                    else if (isRTXingqi)
                    {
                        if (lstRNumEveryDay == null) rNumberCurDay = "所有号牌";
                        else
                        {
                            var t = (int)(dateCur.DayOfWeek) % 7;
                            if (t == 0 || t > 5) continue;

                            rNumberCurDay = lstRNumEveryDay[t - 1];
                            if (rNumberCurDay == "-1") continue; // "不限号";
                        }
                    }
                    else if (isRTRiqiDanshuang || isRTXiuxiriDanShuang)
                    {
                        var t = dateCur.Day % 2;
                        rNumberCurDay = t == 0 ? shuanghaoR : danhaoR;
                    }
                    else if (isRTRun4Pause4)
                    {
                        rNumberCurDay = "开四停四";
                    }
                    #endregion

                    var llItem = new LLItem
                    {
                        city_code = cityCode.ToString(),
                        date = dateCur.ToString(dateFormate),
                        holiday_r = isHolidayR ? 1 : 0,
                        type = Convert.ToInt32(rType),
                        license_attri = Convert.ToInt32(bendiwaidiType),
                        number = rNumberCurDay,
                        english_number = Convert.ToInt32(englishR),
                        register = Convert.ToInt32(waidiRegisterType),
                        id = 0,
                        time = timeRange,
                        date_off_r = isWorkWeekendR ? 1 : 0,
                        thirty_one_r = isThirtyoneR ? 1 : 0,
                        msg_id = Convert.ToInt32(mesIndex),
                        area_id = getAreaId(cityCode, areaIndex)
                    };
                    lstLL.Add(llItem);
                    llCount++;
                }
            }
            #endregion

            #region 写数据
            // 区域表
            var resultT = new string[allAreaCount + 1][];
            string[] headerT = new string[] { "id", "city_code", "area" };
            int iT = 0;
            resultT[iT++] = headerT;
            foreach (var item in dicCityCodeTo_DateToData)
            {
                var areaCity = item.Value.lstArea;
                for (int iArea = 0; iArea < areaCity.Count; iArea++)
                {
                    var dT = new string[headerT.Length];
                    dT[0] = getAreaId(item.Key, iArea).ToString();
                    dT[1] = item.Key.ToString();
                    dT[2] = areaCity[iArea];
                    resultT[iT++] = dT;
                }
            }
            path = Path.Combine(path, "output");
            Write(Path.Combine(path, "区域表.txt"), resultT);

            //写主数据
            resultT = new string[llCount + 1][];
            iT = 0;
            resultT[iT++] = LLItem.GetHeader();
            foreach (var item in dicCityCodeTo_DateToData)
            {
                foreach (var dateD in item.Value.dicDateToData.Values)
                {
                    foreach (var llI in dateD)
                    {
                        resultT[iT++] = llI.GetDataString();
                    }
                }
            }
            Write(Path.Combine(path, "主数据.txt"), resultT);
            #endregion
        }

        public class LLItem
        {
            public int id;
            public string city_code;
            public string date;
            /// <summary>
            /// 本地外地
            /// </summary>
            public int license_attri;
            public int register;
            public int type;
            public int date_off_r;
            public int thirty_one_r;
            public int holiday_r;
            public string time;
            public string number;
            public int english_number;
            public int area_id;
            public int msg_id;

            public static string[] GetHeader()
            {
                var fields = typeof(LLItem).GetFields();
                return fields.Select(item => item.Name).ToArray();
            }

            public string[] GetDataString()
            {
                var fields = typeof(LLItem).GetFields();
                return fields.Select(item => item.GetValue(this).ToString()).ToArray();
            }

            public override string ToString()
            {
                var sb = new StringBuilder();
                foreach (var fieldInfo in this.GetType().GetFields())
                {
                    sb.Append(string.Format("{0}:{1},", fieldInfo.Name, fieldInfo.GetValue(this)));
                }
                return sb.ToString();
            }
        }
    }
}
