Rails.application.routes.draw do
 get 'rlquery/city_info'

  get 'rlquery/index'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'rlquery#index'
	  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
