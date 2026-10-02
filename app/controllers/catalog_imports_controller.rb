class CatalogImportsController < ApplicationController
  MAX_FILE_SIZE = 2.megabytes

  def create
    vendor = Vendor.find(params[:vendor_id])
    file = params[:file]

    unless file.is_a?(ActionDispatch::Http::UploadedFile)
      return render json: { error: "Upload a catalog using the file field" },
                    status: :bad_request
    end

    if file.size > MAX_FILE_SIZE
      return render json: { error: "File must be 2 MB or smaller" },
                    status: :bad_request
    end

    config = CatalogImporter.directory_config.values.find do |entry|
      entry.fetch(:vendor_name) == vendor.name
    end

    unless config
      return render json: { error: "No catalog parser is configured for this vendor" },
                    status: :unprocessable_entity
    end

    result = CatalogImporter.new(
      vendor: vendor,
      contents: file.read,
      parser_class: config.fetch(:parser_class)
    ).call

    render json: result, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Vendor not found" }, status: :not_found
  rescue CatalogImporter::InvalidFile => error
    render json: { error: error.message }, status: :bad_request
  end
end
