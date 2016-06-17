Rails.application.routes.draw do
scope(:path => '/llweb') do 
# get 'home/index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
get 'home/resetByFile'
post 'home/resetByFileComplete'
get 'home/main'
match 'home/resetByFileComplete' => 'home#main' , :via => :get
get 'home/edit'
post 'home/edit_item'
match 'home/edit_item' => 'home#main' , :via => :get
match 'home/index' => 'home#main' , :via => :get
get 'home/download'
root 'home#index'
end
end
