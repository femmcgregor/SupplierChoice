# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_01_190000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "product_equivalences", force: :cascade do |t|
    t.string "name", null: false
    t.string "pack_size", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "products", force: :cascade do |t|
    t.bigint "vendor_id", null: false
    t.string "name"
    t.string "sku"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "product_equivalence_id"
    t.index ["product_equivalence_id", "vendor_id"], name: "index_products_on_equivalence_and_vendor", unique: true, where: "(product_equivalence_id IS NOT NULL)"
    t.index ["product_equivalence_id"], name: "index_products_on_product_equivalence_id"
    t.index ["vendor_id", "sku"], name: "index_products_on_vendor_id_and_sku", unique: true
    t.index ["vendor_id"], name: "index_products_on_vendor_id"
  end

  create_table "vendors", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "products", "product_equivalences"
  add_foreign_key "products", "vendors"
end
