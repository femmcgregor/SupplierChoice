require "test_helper"

class CatalogParsersTest < ActiveSupport::TestCase
  test "NorthParser parses valid CSV rows" do
    rows = CatalogParsers::NorthParser.new(<<~CSV).call
      sku,name,price
      TEST-1,Rice,18.50
      TEST-2,Oil,12.00
    CSV

    assert_equal [
      { "sku" => "TEST-1", "name" => "Rice", "price" => "18.50" },
      { "sku" => "TEST-2", "name" => "Oil", "price" => "12.00" }
    ], rows
  end

  test "NorthParser raises when required columns are missing" do
    error = assert_raises(CatalogParsers::InvalidFile) do
      CatalogParsers::NorthParser.new(<<~CSV).call
        sku,name
        TEST-1,Rice
      CSV
    end

    assert_match(/Missing required columns: price/, error.message)
  end

  test "HarborParser parses variable-length product records starting with 000xxx" do
    rows = CatalogParsers::HarborParser.new(<<~HB).call
      000001
      Chicken Breasts
      20.95
      000002
      Chicken
      Thighs
      10.99
    HB

    assert_equal [
      { "sku" => "000001", "name" => "Chicken Breasts", "price" => "20.95" },
      { "sku" => "000002", "name" => "Chicken Thighs", "price" => "10.99" }
    ], rows
  end

  test "HarborParser imports every product from the sample catalog" do
    contents = Rails.root.join("imports/harbor/sample_catalog.hb").read

    rows = CatalogParsers::HarborParser.new(contents).call

    assert_equal [
      { "sku" => "000002", "name" => "Chicken Thighs", "price" => "10.99" },
      { "sku" => "000003", "name" => "Corn, Canned", "price" => "1.99" },
      { "sku" => "000004", "name" => "Peas, Canned", "price" => "1.5" },
      { "sku" => "000007", "name" => "Chicken Breasts", "price" => "20.95" }
    ], rows
  end

  test "HarborParser raises when a product block is missing a name or price" do
    error = assert_raises(CatalogParsers::InvalidFile) do
      CatalogParsers::HarborParser.new(<<~HB).call
        000001
        Chicken Breasts
      HB
    end

    assert_match(/missing a name or price/, error.message)
  end
end
