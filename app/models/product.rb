class Product < ApplicationRecord
  belongs_to :vendor
  belongs_to :product_equivalence, optional: true

  validates :name, :sku, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :sku, uniqueness: { scope: :vendor_id }
  validates :vendor_id, uniqueness: { scope: :product_equivalence_id }, if: :product_equivalence_id?
end
