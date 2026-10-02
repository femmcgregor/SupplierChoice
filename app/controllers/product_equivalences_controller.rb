class ProductEquivalencesController < ApplicationController
  class RequestError < StandardError
    attr_reader :status

    def initialize(message, status)
      super(message)
      @status = status
    end
  end

  def create
    ids = parse_product_ids(params[:product_ids])
    unless ids
      return render_error("product_ids must contain at least two distinct positive integers", :bad_request)
    end

    unless params[:name].is_a?(String) && params[:pack_size].is_a?(String)
      return render_error("name and pack_size must be strings", :bad_request)
    end

    if params[:name].strip.empty? || params[:pack_size].strip.empty?
      return render_error("name and pack_size must not be blank", :unprocessable_entity)
    end

    comparison = Product.transaction do
      # Lock in a consistent order; validate membership after acquiring locks.
      products = Product.where(id: ids).order(:id).lock.to_a

      unless products.length == ids.length
        raise RequestError.new("One or more products were not found", :unprocessable_entity)
      end
      unless products.map(&:vendor_id).uniq.length == products.length
        raise RequestError.new("Products must belong to different vendors", :unprocessable_entity)
      end
      if products.any? { |product| product.product_equivalence_id.present? }
        raise RequestError.new("A product already belongs to a comparison group", :conflict)
      end

      equivalence = ProductEquivalence.create!(
        name: params[:name].strip,
        pack_size: params[:pack_size].strip
      )
      products.each { |product| product.update!(product_equivalence: equivalence) }

      result = equivalence.comparison
      unless result
        raise RequestError.new("Comparison needs at least two offers", :unprocessable_entity)
      end
      result
    end

    render json: comparison, status: :created
  rescue RequestError => error
    render_error(error.message, error.status)
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

    ids = values.map do |value|
      return unless value.is_a?(String) || value.is_a?(Integer)
      return unless value.to_s.match?(/\A[0-9]+\z/)

      Integer(value.to_s, 10)
    end
    ids if ids.all?(&:positive?) && ids.uniq.length == ids.length
  rescue ArgumentError, TypeError
    nil
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
