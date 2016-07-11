shp_path = "/home/aa/myGit/SHP"

file_name_array = []

  Dir.entries(shp_path).each do |dirNameT|
  	cur_p = File.join(shp_path,dirNameT)
    if File.file?(cur_p)
      next
    end 
        
    Dir.entries(cur_p).each do |file_t|
    	cur_f = File.join(cur_p,file_t)
    	if File.file?(cur_f) && file_t == "LinkForDraw.shp"
    		file_name_array << {city: dirNameT, path: cur_f}
    	end
    end
  end

class InfoWrap
	attr_accessor :is_restrict
	attr_accessor :geom_type

end

class AreaGeomWrap
	attr_accessor :geom
	attr_accessor :info_id
	attr_accessor :info_wrap_array
	attr_accessor :admcode
end

require 'rgeo/shapefile'
require File.join('/home/aa/myGit/LL/lib',"geoHelper.rb")
factory = GeoHelper.factory

read_result = []
file_name_array.each do |file_name_|
	RGeo::Shapefile::Reader.open(file_name_[:path]) do |file|
  hash_city = {}
  begin
  	next if !file
    file.each do |record|
  	next if !record || !record.geometry 
    # puts "Record number #{record.index}:"
    # puts "  Geometry: #{record.geometry[0].is_ring?}"
    # puts "  Attributes: #{record.attributes.inspect}"    

    attri = record.attributes
    info_id = attri["RINForID"]
    if !hash_city.key?(info_id)
      lst = []
      hash_city.store(info_id,lst)
    else
      lst = hash_city[info_id]
    end

    record_wrap = AreaGeomWrap.new
    record_wrap.geom = record.geometry
    record_wrap.info_id = info_id
    record_wrap.admcode = attri["AdmCode"]

    info_wrap = InfoWrap.new
    info_wrap.is_restrict = attri["TrafficRes"] > 0
    info_wrap.geom_type = attri["FeatureTyp"]

    record_wrap.info_wrap_array = [info_wrap]
    lst << record_wrap
    # ex = record.geometry[0].points.map { |e|factory.point(e.y,e.x) }
# inner = record.geometry[1].points.map { |e|factory.point(e.y,e.x)  }

#  res = GeoHelper.convert_polygon_with_hole(ex,inner)
# puts res.length

# write_xlsx('left.xls',res.first.map { |e| [e.x,e.y] })
# write_xlsx('right.xls',res.last.map { |e| [e.x,e.y] })
  	end
  rescue NoMethodError => e
  	puts file_name_[:city] + "  发生解析错误"
  	p e
  	next
  end

  read_result << hash_city
 end
end

# read_result 目前是一个hash的数组，hash的value是一个数组，1需要合并这个数组，即把相同形状点的polyline和polygon合并 2需要将环状polygon拆分
p read_result

POLYLINE = "0"
POLYGON = "1"
POLYLINEGON= "2"


read_result.each do |hash_|
  target = []
  # 发现这条是面，且没有线，则自动改成面+线限行
  # 发现有相同形状点的面和线，合成一个
  # 发现带洞的，拆分
  # 生产工具生产的shp文件结果里面没有面+线，而且x，y是反的，y在前

  hash_.value.each do |src_|
  	ok_add = true
  	target.each do |tar_|
  	  if src_.geom.length==tar_.length &&src_.geom.length==1
  	  	if src_.geom[0].rep_equals?(tar_.geom[0])
  	  		tar_.info_wrap_array << src_.info_wrap_array
  	  		ok_add=false
  	  		break
  	  	end
  	  end
  	end

  	if ok_add
  	end

  	tar_ << src_ if ok_add
  end
  hash_.value = target
end

