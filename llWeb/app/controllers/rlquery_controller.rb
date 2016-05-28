class RlqueryController < ApplicationController
  require 'json'

  def json_to_hash(json)
    json_result = JSON.parse json
    return json_result
  end

  require "open-uri"  

  def index
    uri = 'http://120.27.94.60/api/v1/traffic_restrictions/getCityList?key=mxnavi'  
  	html_response = nil  
	open(uri) do |http|  
  	  html_response = http.read  
   	end  
   	city_res= json_to_hash(html_response)
   	@cities=json_to_hash( city_res["data"])
  end

  def city_info
  	# @label_value=params[:label_value]
  	@city_code=params[:city_code]

  	uri = 'http://120.27.94.60/api/v1/traffic_restrictions/getCityRestrict?key=mxnavi&city=' + @city_code  
    html_response2 = nil  
    open(uri) do |http|  
    html_response2 = http.read  
    end  

    @city_detail_text = html_response2
  end
end
