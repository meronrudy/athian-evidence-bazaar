module V1
  class CountryAdaptersController < ActionController::API
    before_action :ensure_catalog_loaded

    def index
      render json: Agevidence::CountryAdapter.includes(:country_method_version).order(:country_code, :adapter_id, :version).map { |adapter| adapter_payload(adapter) }
    end

    def show
      render json: adapter_payload(adapter)
    end

    def validate
      render json: Agevidence::CountryAdapterCatalog.validation_report(adapter.manifest.merge("path" => adapter.manifest["path"]))
    end

    private

    def ensure_catalog_loaded
      Agevidence::CountryAdapterCatalog.sync! if Agevidence::CountryAdapter.none?
    end

    def adapter
      @adapter ||= Agevidence::CountryAdapterCatalog.resolve_adapter!(params[:adapter_id])
    end

    def adapter_payload(adapter)
      report = Agevidence::CountryAdapterCatalog.validation_report(adapter.manifest)
      {
        adapter_id: adapter.adapter_id,
        country_code: adapter.country_code,
        version: adapter.version,
        status: adapter.status,
        method_id: adapter.country_method_version.method_id,
        method_version: adapter.country_method_version.version,
        authority: adapter.manifest.fetch("method").fetch("authority"),
        classification: report.fetch("classification"),
        limitations: adapter.limitations
      }
    end
  end
end

