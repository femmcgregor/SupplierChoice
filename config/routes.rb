Rails.application.routes.draw do
  resources :vendors, only: [] do
    resources :catalog_imports, only: :create
  end

  get "/products", to: "products#index"

  resources :product_equivalences, only: :create do
    get :comparison, on: :member
  end
end
