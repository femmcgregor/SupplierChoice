class ProductsController < ApplicationController
  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 100

  def index
    page = positive_integer_param(:page, default: 1)
    per_page = positive_integer_param(:per_page, default: DEFAULT_PER_PAGE)
    vendor_id = positive_integer_param(:vendor_id)

    errors = []
    errors << "page must be a positive integer" unless page
    errors << "per_page must be between 1 and #{MAX_PER_PAGE}" unless per_page && per_page <= MAX_PER_PAGE
    if params[:vendor_id].present? && vendor_id.nil?
      errors << "vendor_id must be a positive integer"
    end
    return render json: { error: errors.join(", ") }, status: :bad_request if errors.any?

    products = Product.all
    products = products.where(vendor_id: vendor_id) if vendor_id
    total_count = products.count
    total_pages = (total_count + per_page - 1) / per_page

    paged_products = if page > total_pages
      []
    else
      products.includes(:vendor).order(:name, :id).limit(per_page).offset((page - 1) * per_page)
    end

    response.headers["X-Page"] = page.to_s
    response.headers["X-Per-Page"] = per_page.to_s
    response.headers["X-Total-Count"] = total_count.to_s
    response.headers["X-Total-Pages"] = total_pages.to_s

    render json: paged_products.map { |product|
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

  private

  def positive_integer_param(name, default: nil)
    value = params[name]
    return default if value.blank?

    integer = Integer(value)
    integer if integer.positive?
  rescue ArgumentError, TypeError
    nil
  end
end
