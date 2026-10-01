Rails.application.routes.draw do
  
  resources :vendors, only: [] do
    resources :catalog_imports, only: :create
  end

  get "/products", to: "products#index"

end
