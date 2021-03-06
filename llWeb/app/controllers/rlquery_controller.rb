class RlqueryController < ApplicationController
  require 'json'

  def json_to_hash(json)
    if json.class != "".class 
      return json
    end
    json_result = JSON.parse json
    json_result
  end

  require "open-uri"  
  
  def read_api(uri)
   begin
    open(uri) do |http|  
  	  return http.read  
    end 
    rescue
    return "{\"rspcode\":0,\"city\":\"\",\"cityname\":\"访问API失败\",\"localcar\":[],\"foreigncar\":[],\"allcars\":[]}"
      end 
  end

  def index
    uri = 'http://120.27.94.60/api/v1/traffic_restrictions/getCityList?key=mxnavi'  
  	html_response = read_api(uri) 
	
   	city_res= json_to_hash(html_response)
   	@cities=json_to_hash( city_res["data"])
  end

  def city_info
  	# @label_value=params[:label_value]
  	@city_code=params[:city_code]

  	uri = 'http://120.27.94.60/api/v1/traffic_restrictions/getCityGeneral?key=mxnavi&city='  + @city_code 
    html_response1 = read_api(uri)

  	uri = 'http://120.27.94.60/api/v1/traffic_restrictions/getCityRestrict?key=mxnavi&city=' + @city_code  
    html_response2 = read_api(uri)

    @city_general = json_to_hash(html_response1)

    @detail_hash = json_to_hash(html_response2)

    t = @detail_hash["localcar"]
    t = json_to_hash(t) 
    @loca_hash = t

    t = @detail_hash["foreigncar"]
    t = json_to_hash(t) 
    @fori_hash = t

    t = @detail_hash["allcars"]
    t = json_to_hash(t)
    @allc_hash = t
  end
end
