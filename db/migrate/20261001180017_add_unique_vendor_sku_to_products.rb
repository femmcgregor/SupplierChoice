class AddUniqueVendorSkuToProducts < ActiveRecord::Migration[8.1]
def change
  add_index :products, [ :vendor_id, :sku ], unique: true
end
end
