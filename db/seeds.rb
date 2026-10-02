north = Vendor.find_or_create_by!(name: "North Market Foods")
harbor = Vendor.find_or_create_by!(name: "Harbor Supply Co.")

[
  { vendor: north, sku: "NM-101", name: "Long Grain Rice", price: 18.50 },
  { vendor: north, sku: "NM-102", name: "Canned Tomatoes", price: 12.25 },
  { vendor: harbor, sku: "HS-201", name: "Long Grain Rice", price: 17.95 },
  { vendor: harbor, sku: "HS-202", name: "Olive Oil", price: 24.00 }
].each do |attributes|
  product = Product.find_or_initialize_by(
    vendor: attributes.fetch(:vendor),
    sku: attributes.fetch(:sku)
  )
  product.assign_attributes(attributes)
  product.save!
end
