class CatalogImporter
  # Preserve the exception used by the existing upload controller.
  InvalidFile = CatalogParsers::InvalidFile

  def self.directory_config
    {
      "north" => {
        vendor_name: "North Market Foods",
        extension: "*.csv",
        parser_class: CatalogParsers::NorthParser
      },
      "harbor" => {
        vendor_name: "Harbor Supply Co.",
        extension: "*.hb",
        parser_class: CatalogParsers::HarborParser
      }
    }
  end

  def self.import_directory(root: Rails.root.join("imports"))
    directory_config.flat_map do |folder, config|
      directory = root.join(folder)

      unless directory.directory?
        raise InvalidFile, "Import folder does not exist: #{directory}"
      end

      vendor = Vendor.find_by!(name: config.fetch(:vendor_name))

      directory.glob(config.fetch(:extension)).sort.map do |path|
        begin
          summary = new(
            vendor: vendor,
            contents: File.binread(path),
            parser_class: config.fetch(:parser_class)
          ).call

          summary.merge(vendor: vendor.name, file: path.basename.to_s)
        rescue InvalidFile => error
          {
            vendor: vendor.name,
            file: path.basename.to_s,
            error: error.message
          }
        end
      end
    end
  end

  def initialize(
    vendor:,
    contents:,
    parser_class: CatalogParsers::NorthParser
  )
    @vendor = vendor
    @parser = parser_class.new(contents)
  end

  def call
    # Parse the complete file before saving any products.
    rows = @parser.call
    result = { created: 0, updated: 0, failed: 0, errors: [] }

    rows.each.with_index(1) do |row, record_number|
      sku = row.fetch("sku").to_s.strip

      product = @vendor.products.find_or_initialize_by(sku: sku)
      new_product = product.new_record?

      product.assign_attributes(
        name: row.fetch("name").to_s.strip,
        price: row.fetch("price").to_s.strip
      )

      if product.save
        result[new_product ? :created : :updated] += 1
      else
        result[:failed] += 1
        result[:errors] << {
          record: record_number,
          sku: sku,
          message: product.errors.full_messages.join(", ")
        }
      end
    end

    result
  end
end