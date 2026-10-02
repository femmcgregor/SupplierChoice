require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @vendor = Vendor.create!(name: "Page Vendor")
    other_vendor = Vendor.create!(name: "Other Vendor")

    @vendor.products.create!(name: "Alpha", sku: "PAGE-1", price: 1)
    @vendor.products.create!(name: "Beta", sku: "PAGE-2", price: 2)
    other_vendor.products.create!(name: "Gamma", sku: "OTHER-1", price: 3)
  end

  test "filters by vendor and paginates results" do
    get "/products", params: { vendor_id: @vendor.id, page: 2, per_page: 1 }

    assert_response :success
    assert_equal [ "Beta" ], response.parsed_body.map { |product| product.fetch("name") }
    assert_equal "2", response.headers["X-Page"]
    assert_equal "1", response.headers["X-Per-Page"]
    assert_equal "2", response.headers["X-Total-Count"]
    assert_equal "2", response.headers["X-Total-Pages"]
  end

  test "rejects invalid pagination parameters" do
    get "/products", params: { page: 0 }

    assert_response :bad_request
    assert_equal "page must be a positive integer", response.parsed_body.fetch("error")
  end
end
