require "rgeo"

module GeoHelper
	@factory = ::RGeo::Cartesian::simple_factory
	class << self
		def convert_polygon_with_hole(exterior_ring_, interior_ring_)
			return nil unless is_ring?(exterior_ring_) && is_ring?(interior_ring_)
			regular_direction exterior_ring_
			regular_direction interior_ring_

			cross_res = get_cross_points(exterior_ring_, interior_ring_)
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
			return {b:true } if a_diff==0
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
factory = GeoHelper.factory
p1 = factory.point(1, 1)
p2 = factory.point(2, 4)
p3 = factory.point(5, 2)
array = [p1,p2,p3,p1].reverse
puts GeoHelper.convert_polygon_with_hole(array,array)

puts GeoHelper.calc_cross_point(1.5,array)

point5 = factory.point(0, 1)
point6 = factory.point(0, 2)
point7 = factory.point(-1, 1)

# p GeoHelper.linear_interpolation(1.5,p1,p2)

# @factory = ::RGeo::Cartesian.simple_factory
# p1 = @factory.point(1, 1)
# p2 = @factory.point(2, 4)
# p3 = @factory.point(5, 2)
# array = [p1,p2,p3,p1].reverse
# puts array

# ring_ = @factory.line_string(array)

# puts ::RGeo::Cartesian::Analysis.ring_direction(ring_)
# factory = ::RGeo::Geographic::simple_mercator_factory