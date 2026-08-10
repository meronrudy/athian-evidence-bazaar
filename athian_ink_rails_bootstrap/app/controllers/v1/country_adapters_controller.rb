module V1
  class CountryAdaptersController < ActionController::API
    def index
      adapters = Agevidence::CountryAdapterCatalog.sync!
      render json: adapters.map { |adapter| adapter_payload(adapter) }
    end

    def show
      render json: adapter_payload(find_adapter!)
    end

    def validate
      adapter = find_adapter!
      render json: Agevidence::CountryAdapterCatalog.validation_report(adapter.manifest)
    end

    def developer_determinations
      render json: Agevidence::CountryAdapterDeterminationService.determine(find_adapter!, payload_params)
    end
    alias_method :developer_determination, :developer_determinations

    private

    def find_adapter!
      Agevidence::CountryAdapterCatalog.sync! if Agevidence::CountryAdapter.none?
      Agevidence::CountryAdapter.find_by(id: params[:id]) ||
        Agevidence::CountryAdapter.find_by(adapter_id: params[:id]) ||
        Agevidence::CountryAdapterCatalog.resolve_adapter!(params[:id])
    end

    def payload_params
      params[:payload].respond_to?(:to_unsafe_h) ? params[:payload].to_unsafe_h : params[:payload]
    end

    def adapter_payload(adapter)
      {
        id: adapter.id,
        adapter_id: adapter.adapter_id,
        country_code: adapter.country_code,
        version: adapter.version,
        status: adapter.status,
        method_id: adapter.country_method_version.method_id,
        method_version: adapter.country_method_version.version,
        required_evidence: adapter.required_evidence,
        limitations: adapter.limitations,
        validation: Agevidence::CountryAdapterCatalog.validation_report(adapter.manifest),
        program_url: agevidence_country_program_path(adapter.country_program)
      }
    end
  end
end
