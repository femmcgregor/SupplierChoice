class CreateProductEquivalences < ActiveRecord::Migration[8.1]
  def change
    create_table :product_equivalences do |t|
      t.string :name, null: false
      t.string :pack_size, null: false

      t.timestamps
    end

    add_reference :products, :product_equivalence, foreign_key: true
    add_index :products, [ :product_equivalence_id, :vendor_id ],
              unique: true,
              where: "product_equivalence_id IS NOT NULL",
              name: "index_products_on_equivalence_and_vendor"
  end
end
