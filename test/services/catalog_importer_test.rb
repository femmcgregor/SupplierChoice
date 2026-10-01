require "test_helper"

class CatalogImporterTest < ActiveSupport::TestCase
  setup do
    @vendor = Vendor.create!(name: "Import Test Vendor")
  end

  test "saves valid rows and reports invalid rows" do
    result = import(<<~CSV)
      sku,name,price
      TEST-1,Rice,18.50
      TEST-2,Oil,not-a-price
      TEST-3,Tomatoes,-1.00
      TEST-4,,12.00
    CSV

    assert_equal 1, result[:created]
    assert_equal 3, result[:failed]
    assert_equal [2, 3, 4], result[:errors].pluck(:record)
    assert_equal ["TEST-1"], @vendor.products.pluck(:sku)
  end

  test "repeated imports update products without duplicates" do
    import("sku,name,price\nTEST-1,Rice,18.50\n")

    result = import("sku,name,price\nTEST-1,Rice,17.95\n")

    assert_equal 0, result[:created]
    assert_equal 1, result[:updated]
    assert_equal 1, @vendor.products.count
    assert_equal BigDecimal("17.95"), @vendor.products.first.price
  end

  test "the same SKU can belong to different vendors" do
    another_vendor = Vendor.create!(name: "Another Test Vendor")
    another_vendor.products.create!(
      sku: "TEST-1", name: "Rice", price: 20
    )

    result = import("sku,name,price\nTEST-1,Rice,18.50\n")

    assert_equal 1, result[:created]
    assert_equal BigDecimal("20"), another_vendor.products.first.price
  end

  test "missing headers do not save products" do
    assert_raises(CatalogImporter::InvalidFile) do
      import("sku,name\nTEST-1,Rice\n")
    end

    assert_empty @vendor.products
  end

  test "malformed CSV does not save earlier valid rows" do
    assert_raises(CatalogImporter::InvalidFile) do
      import("sku,name,price\nTEST-1,Rice,18.50\nTEST-2,\"Oil,12.00\n")
    end

    assert_empty @vendor.products
  end

  test "harbor files accept variable lines per product and 000xxx markers" do
    result = CatalogImporter.new(
      vendor: @vendor,
      contents: <<~HB,
        000001
        Chicken Breasts
        20.95
        000002
        Chicken
        Thighs
        10.99
        000003
        Corn, Canned
        1.99
      HB
      parser_class: CatalogParsers::HarborParser
    ).call

    assert_equal 3, result[:created]
    assert_equal ["000001", "000002", "000003"], @vendor.products.order(:sku).pluck(:sku)
    assert_equal "Chicken Thighs", @vendor.products.find_by!(sku: "000002").name
    assert_equal BigDecimal("10.99"), @vendor.products.find_by!(sku: "000002").price
  end

  private

  def import(contents)
    CatalogImporter.new(vendor: @vendor, contents: contents).call
  end
end