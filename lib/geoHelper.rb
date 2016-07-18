require "rgeo"

module GeoHelper
	@factory = ::RGeo::Cartesian::simple_factory
	class << self
		# please input closed point array as polygon
		def convert_polygon_with_hole(exterior_ring_, interior_ring_)
			return nil unless is_ring?(exterior_ring_) && is_ring?(interior_ring_)
			regular_direction exterior_ring_
			regular_direction interior_ring_

			cross_res = get_cross_points(exterior_ring_, interior_ring_)
			return nil unless cross_res
			get_polygons(exterior_ring_,interior_ring_,cross_res)
		end

		def get_polygons(exterior_ring_, interior_ring_,cross_point_wraps_)
			calc_geom = lambda do |start_i_, end_i_,ring_,target_|
				compare_v = start_i_ <=> end_i_
				return nil if compare_v == 0
				if compare_v < 0 
					(start_i_+1 ..end_i_).each_with_index do |i|
						target_ << ring_[i]
					end
				else
					(start_i_+1 .. ring_.length-2).each_with_index do |i|
						target_ << ring_[i]
					end
					(0 .. end_i_).each_with_index do |i|
						target_ << ring_[i]
					end
				end
			end			

			get_geom = lambda do |ring_, point_wraps_|
				point_wraps_.sort!{|a,b| a[:p].y <=> b[:p].y}
				bottom = point_wraps_.first
				top = point_wraps_.last
				top_i = top[:i]
				bottom_i = bottom[:i]
				compare_v = top_i <=> bottom_i
				return nil if compare_v == 0
				# now input gem are counter_clockwise
				left = []
				right = []
				
				left << top[:p]
				calc_geom.call(top_i,bottom_i, ring_, left)
				left << bottom[:p] unless bottom[:b]

				right << left.last
				calc_geom.call(bottom_i,top_i,ring_,right)
				right << top[:p] unless top[:b]						

				return [left, right]
			end

			ex_geom = get_geom.call(exterior_ring_,cross_point_wraps_.first)
			in_geom = get_geom.call(interior_ring_,cross_point_wraps_.last)
			# now connect these to polygon
			polygon_left = ex_geom.first+in_geom.first.reverse
			polygon_left << polygon_left.first

			polygon_right = ex_geom.last + in_geom.last.reverse
			polygon_right << polygon_right.first

			[polygon_left,polygon_right]
		end

		def get_cross_points(exterior_ring_, interior_ring_)
			inner_box = calc_boundingbox interior_ring_
			# raise 'nobox' unless inner_box
			return nil unless inner_box
			try_get_cross = ->(v_){
				ex_res = calc_cross_point(v_, exterior_ring_)
				in_res = calc_cross_point(v_, interior_ring_)
				return nil unless ex_res && in_res
				[ex_res,in_res]
			}
			stride = inner_box.x_span / 30.0
			cur_v = inner_box.center_x

			excute = Proc.new { 
				puts cur_v
				res_temp = try_get_cross.call(cur_v)
				return res_temp if res_temp
			}
			while cur_v < inner_box.max_x
				excute.call
				cur_v = cur_v + stride
			end

			cur_v = inner_box.center_x
			while cur_v > inner_box.min_x
				excute.call
				cur_v = cur_v - stride
			end
			nil
		end

		def calc_cross_point (v_ , ring_)
			points=[]
			(0..ring_.length-2).each_with_index do |i|
				p_a_ = ring_[i]
				p_b_ = ring_[i+1]
				res = linear_interpolation(v_,p_a_,p_b_)
				if res
					res[:i] = i
					points << res
				end
			end

			points.length == 2 ? points : nil
		end

		def is_ring? points_
			points_ && points_.length>2 && points_.first==points_.last
		end

		def regular_direction points_
			points_.reverse! if ::RGeo::Cartesian::Analysis.ring_direction(@factory.line_string(points_)) < 0
		end

		def calc_boundingbox points_
			bbox_ = ::RGeo::Cartesian::BoundingBox.new @factory
			points_.each do |p|
				bbox_.add p
			end
			bbox_
		end

		def linear_interpolation(v_,p_a_,p_b_)
			v_ = v_.to_f
			a_diff = p_a_.x - v_
			b_diff = p_b_.x - v_
			return {b:true, p:p_a_} if a_diff==0
			return nil if a_diff * b_diff >=0
			dis_x = p_a_.x - p_b_.x
			dis_y = p_a_.y - p_b_.y
			ratio = (a_diff/dis_x).abs
			{p:@factory.point(v_,p_a_.y-ratio*dis_y)}
		end

		attr_reader :factory
	end
end

# test
# factory = GeoHelper.factory
# point1 = factory.point(1, 0)
# point2 = factory.point(1, 4)
# point3 = factory.point(-2, 0)
# point4 = factory.point(-2, 4)

# # puts GeoHelper.convert_polygon_with_hole(array,array)

# # puts GeoHelper.calc_cross_point(1.5,array)

# point5 = factory.point(0, 1)
# point6 = factory.point(0, 2)
# point7 = factory.point(-1, 1)

# a_ex = [point1,point2,point3,point1]
# a_in = [point5,point6,point7,point5]

# # puts GeoHelper.convert_polygon_with_hole(a_ex,a_in)

# (0...0).each_with_index do |i|
# 	puts i
# end

# mercator = ::RGeo::Geographic::simple_mercator_factory
# # a_ex.shift
# line1 = mercator.linear_ring a_ex
# line2 = mercator.linear_ring a_in

# # require "/home/aa/myGit/rgeo/lib/rgeo/geographic/projected_feature_classes.rb"

# polygon1 = mercator.polygon line1
# polygon2 = mercator.polygon line2
#  p polygon1._validate_geometry
# p polygon2.distance point1
 # puts polygon1.contains? polygon2