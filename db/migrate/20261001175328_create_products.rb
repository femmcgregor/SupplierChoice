class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :vendor, null: false, foreign_key: true
      t.string :name
      t.string :sku
      t.decimal :price, precision: 10, scale: 2, null: false

      t.timestamps
    end
  end
end
