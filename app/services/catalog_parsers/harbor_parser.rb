module CatalogParsers
  class HarborParser < BaseParser
    PRODUCT_CODE = /\A000\d+\z/.freeze

    def call
      lines = normalized_contents.lines.map(&:strip).reject(&:empty?)

      return [] if lines.empty?

      products = []
      current_block = []

      lines.each do |line|
        if line.match?(PRODUCT_CODE)
          products << parse_block(current_block) if current_block.any?
          current_block = [line]
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

      if body.length < 2
        raise InvalidFile, "Harbor product #{sku} is missing a name or price"
      end

      price = body.last
      name = body[0...-1].join(" ").strip

      if name.empty? || price.to_s.strip.empty?
        raise InvalidFile, "Harbor product #{sku} is missing a name or price"
      end

      { "sku" => sku, "name" => name, "price" => price }
    end
  end
end