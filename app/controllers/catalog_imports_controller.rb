class CatalogImportsController < ApplicationController
  MAX_FILE_SIZE = 2.megabytes

  def create
    vendor = Vendor.find(params[:vendor_id])
    file = params[:file]

    unless file.is_a?(ActionDispatch::Http::UploadedFile)
      return render json: { error: "Upload a CSV using the file field" },
                    status: :bad_request
    end

    if file.size > MAX_FILE_SIZE
      return render json: { error: "File must be 2 MB or smaller" },
                    status: :bad_request
    end

    result = CatalogImporter.new(
      vendor: vendor,
      contents: file.read
    ).call

    render json: result, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Vendor not found" }, status: :not_found
  rescue CatalogImporter::InvalidFile => error
    render json: { error: error.message }, status: :bad_request
  end
end