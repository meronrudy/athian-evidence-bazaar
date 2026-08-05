module Agevidence
  class PolicyProfile
    TYPES = %w[
      methodology disclosure assurance rights data_policy verifier registry
      buyer lender processor government institution
    ].freeze

    attr_reader :profile_type, :profile_id, :version, :authority, :requirements, :limitations, :conflicts, :payload

    def initialize(profile_type:, profile_id:, version:, authority: nil, requirements: [], limitations: [], conflicts: [], payload: {})
      @profile_type = profile_type
      @profile_id = profile_id
      @version = version
      @authority = authority
      @requirements = Array(requirements)
      @limitations = Array(limitations)
      @conflicts = Array(conflicts)
      @payload = payload
    end

    def to_h(layer:)
      {
        "layer" => layer,
        "profile_type" => profile_type,
        "profile_id" => profile_id,
        "version" => version,
        "authority" => authority,
        "requirements" => requirements,
        "limitations" => limitations,
        "conflicts" => conflicts
      }.compact
    end
  end
end
