Rails.application.routes.draw do
  root "works#index"

  resources :works, only: [:index, :show]

  namespace :api, defaults: { format: "json" } do
    resources :works, only: [:index, :show]
    get "/", to: "errors#not_found"
    get "*unmatched", to: "errors#not_found"
  end
end
