Rails.application.routes.draw do
  root "works#index"

  resources :works, only: [:index, :show]

  namespace :api, defaults: { format: :json } do
    resources :works, only: [:index, :show]
  end
end
