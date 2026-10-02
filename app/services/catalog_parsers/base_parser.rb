module CatalogParsers
  class BaseParser
    def initialize(contents)
      @contents = contents
    end

    private

    def normalized_contents
      contents = @contents.dup.force_encoding(Encoding::UTF_8)

      unless contents.valid_encoding?
        raise InvalidFile, "File must use UTF-8 encoding"
      end

      contents.delete_prefix("\uFEFF")
    end
  end
end
