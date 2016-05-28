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
end
