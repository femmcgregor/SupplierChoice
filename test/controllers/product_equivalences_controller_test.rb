require "test_helper"

class ProductEquivalencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    north = Vendor.create!(name: "North")
    harbor = Vendor.create!(name: "Harbor")

    @north_rice = north.products.create!(name: "Long Grain Rice", sku: "NORTH-RICE", price: 18.50)
    @harbor_rice = harbor.products.create!(name: "Rice, Long Grain", sku: "HARBOR-RICE", price: 17.95)
  end

  test "creates an explicit equivalence and returns the cheapest offer with savings" do
    post "/product_equivalences", params: {
      name: "Long Grain Rice",
      pack_size: "10 lb bag",
      product_ids: [ @north_rice.id, @harbor_rice.id ]
    }

    assert_response :created
    result = response.parsed_body
    assert_equal "10 lb bag", result.fetch("pack_size")
    assert_equal @harbor_rice.id, result.dig("cheapest_offer", "product_id")
    assert_equal "0.55", result.fetch("savings_per_pack")
    assert_equal "North's Long Grain Rice (10 lb bag) costs $18.50 per pack and Harbor's equivalent pack costs $17.95 per pack, so Harbor saves $0.55 per pack.", result.fetch("explanation")

    get "/product_equivalences/#{result.fetch('id')}/comparison"

    assert_response :success
    assert_equal @harbor_rice.id, response.parsed_body.dig("cheapest_offer", "product_id")
  end

  test "rejects linking multiple products from one vendor" do
    second_north_product = @north_rice.vendor.products.create!(
      name: "Brown Rice",
      sku: "NORTH-BROWN-RICE",
      price: 16.00
    )

    post "/product_equivalences", params: {
      name: "Rice",
      pack_size: "10 lb bag",
      product_ids: [ @north_rice.id, second_north_product.id ]
    }

    assert_response :unprocessable_entity
    assert_equal "Products must belong to different vendors", response.parsed_body.fetch("error")
  end
end
