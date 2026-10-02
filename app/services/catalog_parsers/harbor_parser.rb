module CatalogParsers
  class HarborParser < BaseParser
    # A record code may have an optional V prefix. Lines after the price
    # contain pack details and are not part of the product name.
    PRODUCT_CODE = /\AV?000\d+\z/.freeze
    PRICE = /\A\d+(?:\.\d{1,2})?\z/.freeze

    def call
      lines = normalized_contents.lines.map(&:strip).reject(&:empty?)

      return [] if lines.empty?

      products = []
      current_block = []

      lines.each do |line|
        if line.match?(PRODUCT_CODE)
          products << parse_block(current_block) if current_block.any?
          current_block = [ line ]
        else
          current_block << line
        end
      end

      products << parse_block(current_block) if current_block.any?
      products
    end

    private

    def parse_block(block)
      sku = block.first

      unless sku.to_s.match?(PRODUCT_CODE)
        raise InvalidFile, "Harbor files must begin with a product code in the format 000xxx"
      end

      body = block.drop(1)

      price_index = body.rindex { |line| line.match?(PRICE) }
      if price_index.nil? || price_index.zero?
        raise InvalidFile, "Harbor product #{sku} is missing a name or price"
      end

      price = body[price_index]
      name = body[0...price_index].join(" ").strip

      if name.empty? || price.to_s.strip.empty?
        raise InvalidFile, "Harbor product #{sku} is missing a name or price"
      end

      { "sku" => sku, "name" => name, "price" => price }
    end
  end
end
