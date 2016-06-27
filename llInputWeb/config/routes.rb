Rails.application.routes.draw do
  get 'lldetail/main'

	scope(:path => '/llweb') do 
# get 'home/index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'home/resetByFile'
  post 'home/import'
  get 'home/main'
  match 'home/import' => 'home#main' , :via => :get
  get 'home/edit'
  post 'home/edit_item'
  match 'home/edit_item' => 'home#main' , :via => :get
  match 'home/index' => 'home#main' , :via => :get
  get 'home/download'

  get 'eventll/main'
  get 'eventll/resetByFile'
  post 'eventll/import'
  match 'eventll/import' => 'eventll#main' , :via => :get
  get 'eventll/edit'
  post 'eventll/edit_item'
  match 'eventll/edit_item' => 'eventll#main' , :via => :get
  match 'eventll/index' => 'eventll#main' , :via => :get
  get 'eventll/download'

  get 'lldetail/main'
  get 'lldetail/resetByFile'
  post 'lldetail/import'
  match 'lldetail/import' => 'lldetail#main' , :via => :get
  get 'lldetail/edit'
  post 'lldetail/edit_item'
  match 'lldetail/edit_item' => 'lldetail#main' , :via => :get
  match 'lldetail/index' => 'lldetail#main' , :via => :get
  get 'lldetail/download'

  root 'home#index'
end
end
