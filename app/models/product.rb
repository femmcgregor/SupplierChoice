class Product < ApplicationRecord
  belongs_to :vendor

  validates :name, :sku, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :sku, uniqueness: { scope: :vendor_id }
end
