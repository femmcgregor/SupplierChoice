# Supplier Choice API

This project imports supplier catalog files into a Rails application and stores the parsed products for each vendor.

The app currently supports:

- CSV imports for the North catalog format
- Harbor `.hb` imports with product records beginning with `000xxx` codes

## Prerequisites

- Ruby 3.x
- Bundler
- PostgreSQL
- Rails 8.1.4

## Local setup

1. Install dependencies:

   ```bash
   bundle install
   ```

2. Create and initialize the database:

   ```bash
   bin/rails db:prepare
   ```

3. Start the server:

   ```bash
   bin/rails server
   ```

4. Optional: run the test suite:

   ```bash
   bin/rails test
   ```

## Sample import files

Sample files live under the `imports` directory:

- `imports/north/sample_catalog.csv`
- `imports/harbor/sample_catalog.hb`

Example North CSV:

```csv
sku,name,price
NM-101,Long Grain Rice,17.95
NM-103,Pasta,9.50
NM-104,Olive Oil,invalid
```

Example Harbor record format:

```text
000002
Chicken Thighs
10.99
000003
Corn, Canned
1.99
6/case
000004
Peas, Canned
1.5
6 #10 Can
000007
Chicken Breasts
20.95
```

The Harbor format is parsed as a block of lines beginning with a product code (`000xxx`). The final line in each block is treated as the price, and the remaining lines are joined into the product name.

## Catalog imports

Upload a catalog for a configured vendor with a multipart `file` field. The parser is selected from the vendor, and uploads are limited to 2 MB.

```sh
curl -X POST http://localhost:3000/vendors/1/catalog_imports \
   -F 'file=@imports/north/sample_catalog.csv'
```

## Products API

`GET /products` returns a JSON array of products. Filter by vendor and paginate with optional query parameters:

```sh
curl 'http://localhost:3000/products?vendor_id=1&page=1&per_page=20'
```

`vendor_id` is optional. `page` defaults to 1, and `per_page` defaults to 20 with a maximum of 100. The response includes `X-Page`, `X-Per-Page`, `X-Total-Count`, and `X-Total-Pages` headers. Invalid parameter values return `400 Bad Request`.

## Product comparisons

Create a comparison by explicitly linking product IDs from different vendors. All linked products share the declared pack size; names are descriptive and are not used to infer equivalence.

```sh
curl -X POST http://localhost:3000/product_equivalences \
   -H 'Content-Type: application/json' \
   -d '{"name":"Long Grain Rice","pack_size":"10 lb bag","product_ids":[12,34]}'
```

The response includes all linked offers, the cheapest offer, savings per pack, and an explanation. Retrieve the comparison again with `GET /product_equivalences/:id/comparison`. For example: “North's Long Grain Rice (10 lb bag) costs $18.50 per pack and Harbor's equivalent pack costs $17.95 per pack, so Harbor saves $0.55 per pack.”

## Demo walkthrough

1. Start the app:

   ```bash
   bin/rails server
   ```

2. Create or update a vendor in the database, for example `Harbor Supply Co.` or `North Market Foods`.

3. Import a catalog file through the importer flow.

   ```ruby
   vendor = Vendor.find_by!(name: "Harbor Supply Co.")
   contents = File.read("imports/harbor/sample_catalog.hb")
   result = CatalogImporter.new(vendor: vendor, contents: contents, parser_class: CatalogParsers::HarborParser).call
   ```

4. Inspect the result:

   ```ruby
   result[:created]
   result[:updated]
   result[:failed]
   ```

5. Confirm product rows were saved:

   ```ruby
   vendor.products.order(:sku).pluck(:sku, :name, :price)
   ```

## Notes

- The importer parses the complete file before saving rows; malformed files do not save any products.
- After parsing succeeds, valid rows are saved independently. Row validation failures are reported in the result while other valid rows from the same import remain saved.
- The Harbor parser accepts variable-length blocks as long as each new product starts with a `000xxx` code.
