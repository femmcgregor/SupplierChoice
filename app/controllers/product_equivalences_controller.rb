class ProductEquivalencesController < ApplicationController
  def create
    ids = parse_product_ids(params[:product_ids])
    return render_error("product_ids must contain at least two distinct positive integers", :bad_request) unless ids

    products = Product.where(id: ids).includes(:vendor).to_a
    return render_error("One or more products were not found", :unprocessable_entity) unless products.length == ids.length
    return render_error("Products must belong to different vendors", :unprocessable_entity) unless products.map(&:vendor_id).uniq.length == products.length
    return render_error("A product already belongs to a comparison group", :conflict) if products.any?(&:product_equivalence_id?)

    comparison = nil
    Product.transaction do
      equivalence = ProductEquivalence.create!(
        name: params[:name].to_s.strip,
        pack_size: params[:pack_size].to_s.strip
      )
      products.each { |product| product.update!(product_equivalence: equivalence) }
      comparison = equivalence.comparison
    end

    render json: comparison, status: :created
  rescue ActiveRecord::RecordInvalid => error
    render_error(error.record.errors.full_messages.join(", "), :unprocessable_entity)
  end

  def comparison
    equivalence = ProductEquivalence.find(params[:id])
    result = equivalence.comparison
    return render_error("Comparison needs at least two offers", :unprocessable_entity) unless result

    render json: result
  rescue ActiveRecord::RecordNotFound
    render_error("Product comparison not found", :not_found)
  end

  private

  def parse_product_ids(values)
    return unless values.is_a?(Array) && values.length >= 2

    ids = values.map { |value| Integer(value) }
    ids if ids.all?(&:positive?) && ids.uniq.length == ids.length
  rescue ArgumentError, TypeError
    nil
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
