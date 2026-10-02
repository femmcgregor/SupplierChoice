class ProductEquivalence < ApplicationRecord
  has_many :products, dependent: :nullify

  validates :name, :pack_size, presence: true

  def comparison
    offers = products.includes(:vendor).order(:price, :id).to_a
    return if offers.length < 2

    cheapest, alternative = offers.first(2)
    savings = alternative.price - cheapest.price

    {
      id: id,
      name: name,
      pack_size: pack_size,
      cheapest_offer: offer_attributes(cheapest),
      offers: offers.map { |product| offer_attributes(product) },
      savings_per_pack: format_price(savings),
      explanation: explanation(cheapest, alternative, savings)
    }
  end

  private

  def offer_attributes(product)
    {
      product_id: product.id,
      name: product.name,
      sku: product.sku,
      price: format_price(product.price),
      vendor: {
        id: product.vendor.id,
        name: product.vendor.name
      }
    }
  end

  def explanation(cheapest, alternative, savings)
    if savings.zero?
      "#{cheapest.vendor.name} and #{alternative.vendor.name} tie at " \
        "$#{format_price(cheapest.price)} per pack for #{name} (#{pack_size})."
    else
      "#{alternative.vendor.name}'s #{name} (#{pack_size}) costs " \
        "$#{format_price(alternative.price)} per pack and " \
        "#{cheapest.vendor.name}'s equivalent pack costs " \
        "$#{format_price(cheapest.price)} per pack, so " \
        "#{cheapest.vendor.name} saves $#{format_price(savings)} per pack."
    end
  end

  def format_price(price)
    format("%.2f", price)
  end
end
