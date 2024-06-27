Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'chatai#new'
  get 'chatai/new' => 'chatai#new'
  post 'chatai/create' => 'chatai#create'

  get 'chatbot/index' => 'chatbot#index'
  get 'chatbot/new' => 'chatbot#new'
  post 'chatbot/create' => 'chatbot#create'
  get 'chatbot/reset' => 'chatbot#reset'
  get 'chatbot/:id' => 'chatbot#show'
end
