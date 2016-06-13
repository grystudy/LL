Rails.application.routes.draw do
  get 'home/index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
get 'home/resetByFile'
post 'home/resetByFileComplete'
get 'home/main'
match 'home/resetByFileComplete' => 'home#index' , :via => :get

root 'home#index'
end
