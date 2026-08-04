module InkReceipts
  module BundleProfiles
    def self.profile_for(bundle_type)
      InkReceipts::BUNDLE_TYPES.fetch(bundle_type.to_s)
    end
  end
end
