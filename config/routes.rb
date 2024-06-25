Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get 'chatai/new' => 'chatai#new'
  post 'chatai/create' => 'chatai#create'
  get 'chatbot/new' => 'chatbot#new'
  post 'chatbot/create' => 'chatbot#create'
end
