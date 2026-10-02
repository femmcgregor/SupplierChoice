class ProductsController < ApplicationController
  def index
    products = Product.includes(:vendor).order(:name, :id)

    render json: products.map { |product|
      {
        id: product.id,
        name: product.name,
        sku: product.sku,
        price: product.price.to_s,
        vendor: {
          id: product.vendor.id,
          name: product.vendor.name
        }
      }
    }
  end
end
