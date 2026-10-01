require "csv"

module CatalogParsers
  class NorthParser < BaseParser
    REQUIRED_HEADERS = %w[sku name price].freeze

    def call
      table = CSV.parse(
        normalized_contents,
        headers: true,
        header_converters: ->(header) { header.strip.downcase },
        skip_blanks: true
      )

      headers = table.headers.compact

      if headers.uniq.length != headers.length
        raise InvalidFile, "CSV contains duplicate column headers"
      end

      missing = REQUIRED_HEADERS - headers

      if missing.any?
        raise InvalidFile, "Missing required columns: #{missing.join(', ')}"
      end

      table.map do |row|
        REQUIRED_HEADERS.to_h { |header| [header, row[header]] }
      end
    rescue CSV::MalformedCSVError => error
      raise InvalidFile, "Invalid CSV: #{error.message}"
    end
  end
end