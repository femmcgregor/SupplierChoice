require "pathname"

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
    root = Pathname.new(root)
    # Resolve every directory and vendor before saving any products.
    sources = directory_config.map do |folder, config|
      directory = root.join(folder)
      unless directory.directory?
        raise InvalidFile, "Import folder does not exist: #{directory}"
      end
      vendor = Vendor.find_by(name: config.fetch(:vendor_name))
      unless vendor
        raise InvalidFile, "Vendor not found: #{config.fetch(:vendor_name)}"
      end
      [ directory, vendor, config ]
    end

    sources.flat_map do |directory, vendor, config|
      directory.glob(config.fetch(:extension)).sort.map do |path|
        begin
          summary = new(
            vendor: vendor,
            contents: File.binread(path),
            parser_class: config.fetch(:parser_class)
          ).call
          summary.merge(vendor: vendor.name, file: path.basename.to_s)
        rescue InvalidFile, SystemCallError => error
          { vendor: vendor.name, file: path.basename.to_s, error: error.message }
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
    result = { created: 0, updated: 0, unchanged: 0, failed: 0, errors: [] }

    rows.each.with_index(1) do |row, record_number|
      outcome, messages = save_row(row)
      result[outcome] += 1
      if outcome == :failed
        result[:errors] << {
          record: record_number,
          sku: row.fetch("sku").to_s.strip,
          message: messages.join(", ")
        }
      end
    end
    result
  end

  private

  def save_row(row)
    sku = row.fetch("sku").to_s.strip
    attempts = 0

    begin
      attempts += 1
      # A savepoint allows recovery from a unique violation in PostgreSQL,
      # including when the caller already has an open transaction.
      Product.transaction(requires_new: true) do
        product = @vendor.products.find_or_initialize_by(sku: sku)
        new_product = product.new_record?
        product.assign_attributes(
          name: row.fetch("name").to_s.strip,
          price: row.fetch("price").to_s.strip
        )
        changed = product.changed?

        if product.save
          outcome = new_product ? :created : (changed ? :updated : :unchanged)
          [ outcome, [] ]
        else
          [ :failed, product.errors.full_messages ]
        end
      end
    rescue ActiveRecord::RecordNotUnique
      # Reload through a fresh lookup after another writer creates the SKU.
      retry if attempts < 2
      [ :failed, [ "Product conflicted with another import; retry this record" ] ]
    end
  end
end
