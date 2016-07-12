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

	def to_json(*a)
		{IsRestrict: is_restrict, shapetype:geom_type}.to_json()
	end
end

class AreaGeomWrap
	attr_accessor :geom
	attr_accessor :info_id
	attr_accessor :info_wrap_array
	attr_accessor :admcode

	def to_json(*a)
		{Geo:geom.to_json,restInfo: info_wrap_array.to_json}.to_json()
	end
end

require 'rgeo/shapefile'
require File.join('/home/aa/myGit/LL/lib',"geoHelper.rb")
factory = GeoHelper.factory

class ::RGeo::Cartesian::PointImpl
	def to_json(*a)
		{x: x,y: y}.to_json
	end
end

read_result = []
file_name_array.each do |file_name_|
	RGeo::Shapefile::Reader.open(file_name_[:path]) do |file|
		hash_city = {}
		begin
			next if !file
			file.each do |record|
				next if !record || !record.geometry 
				attri = record.attributes
				info_id = attri["RINForID"]
				if !hash_city.key?(info_id)
					lst = []
					hash_city.store(info_id,lst)
				else
					lst = hash_city[info_id]
				end

				record_wrap = AreaGeomWrap.new
				record_wrap.geom = []
				if record.geometry
					record.geometry.each_with_index do |geo_,i_|
						record_wrap.geom << geo_.points.map { |e|factory.point(e.y,e.x)  }
					end
				end
				record_wrap.info_id = info_id
				record_wrap.admcode = attri["AdmCode"]

				info_wrap = InfoWrap.new
				info_wrap.is_restrict = attri["TrafficRes"] > 0
				info_wrap.geom_type = attri["FeatureTyp"]

				record_wrap.info_wrap_array = [info_wrap]
				lst << record_wrap
			end
		rescue NoMethodError => e
			puts file_name_[:city] + "  发生解析错误"
			p e
			next
		end

		read_result << hash_city
	end
end

# read_result 目前是一个hash的数组，hash(infoid=>items)的value是一个数组，1需要合并这个数组，即把相同形状点的polyline和polygon合并 2需要将环状polygon拆分
# p read_result

POLYLINE = "0"
POLYGON = "1"
POLYLINEGON= "2"

# 2 发现这条是面，且没有线，则自动改成面+线限行,ignore double_ring
# 1 发现有相同形状点的面和线，合成一个,igonre double_ring
# 3 发现带洞的，拆分
# 4 生产工具生产的shp文件结果里面没有面+线，而且x，y是反的，y在前
read_result.each do |hash_|
	hash_.each do |infoid_,items_|
		target = []
		items_.each do |src_|
			ok_add = true
			target.each do |tar_|
				if src_.geom.length==tar_.geom.length &&src_.geom.length==1
					if factory.line_string(src_.geom[0]).rep_equals?(factory.line_string(tar_.geom[0]))
						tar_.info_wrap_array << src_.info_wrap_array
						ok_add=false
						break
					end
				end
	  		#process polygon_with_hole
	  		obj_to_extend = nil 
	  		ex_same = false
	  		in_same = false

	  		try = lambda do |a_,b_|
	  			if a_.geom.length == 1 && b_.geom.length ==2
	  				if factory.line_string(a_.geom[0]).rep_equals?(factory.line_string(b_.geom[0]))
	  					obj_to_extend = b_
	  					ex_same =true
	  					return true
	  				elsif factory.line_string(a_.geom[0]).rep_equals?(factory.line_string(b_.geom[1]))
	  					obj_to_extend = b_
	  					in_same =true
	  					return true
	  				end
	  			end
	  			return false
	  		end

	  		try.call(src_,tar_) unless try.call(tar_,src_)

	  		if obj_to_extend		
	  			class << obj_to_extend
	  				attr_accessor :ex_auto
	  				attr_accessor :in_auto
	  			end unless obj_to_extend.respons_to?(:ex_auto)

	  			obj_to_extend.ex_auto = false if ex_same
	  			obj_to_extend.in_auto = false if in_same
	  			break
	  		end
	  	end
	  	target << src_ if ok_add
	  end

	  items_.clear
	  items_[0,0] = target

	  items_to_add = []
	  items_.each do |src_|
	  	if src_.info_wrap_array.length==1 && src_.geom.length == 1
	  		t = src_.info_wrap_array.first
	  		t.geom_type = POLYLINEGON if t.geom_type == POLYGON && t.is_restrict
	  	end

	  	if src_.geom.length == 2
	  		ori_geom = src_.geom  
	  		splitted = GeoHelper.convert_polygon_with_hole(ori_geom.first,ori_geom.last)
	  		if splitted
	  			if src_.respond_to?(:ex_auto)
	  				if src_.ex_auto
	  					info_t = InfoWrap.new
	  					info_t.is_restrict =true
	  					info_t.geom_type = POLYLINE

	  					geom_wrap = AreaGeomWrap.new
	  					geom_wrap.infoid = src.infoid
	  					geom_wrap.admcode = src.admcode
	  					geom_wrap.geom = ori_geom.first
	  					geom_wrap.info_wrap_array = [info_t]

	  					items_to_add << geom_wrap
	  				end

	  				if src_.in_auto
	  					info_t = InfoWrap.new
	  					info_t.is_restrict =true
	  					info_t.geom_type = POLYLINE

	  					geom_wrap = AreaGeomWrap.new
	  					geom_wrap.infoid = src.infoid
	  					geom_wrap.admcode = src.admcode
	  					geom_wrap.geom = ori_geom.last
	  					geom_wrap.info_wrap_array = [info_t]

	  					items_to_add << geom_wrap
	  				end

	  				info_t = InfoWrap.new
	  				info_t.is_restrict =true
	  				info_t.geom_type = POLYGON

	  				geom_wrap = AreaGeomWrap.new
	  				geom_wrap.infoid = src.infoid
	  				geom_wrap.admcode = src.admcode
	  				geom_wrap.geom = splitted.left
	  				geom_wrap.info_wrap_array = [info_t]

	  				items_to_add << geom_wrap

	  				src.geom = splitted.right
	  				src.info_wrap_array = [info_t]
	  			end
	  		end
	  	end
	  end
	  items_[items_.length,0] = items_to_add
	end
end

# require 'json'
json_res = read_result.to_json
# obj = JSON.parse json_res
File.open("限行形状转换.txt", "w", :encoding => 'UTF-8') do |io|
	io.write json_res
end