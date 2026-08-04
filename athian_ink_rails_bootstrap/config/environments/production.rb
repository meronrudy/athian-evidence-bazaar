require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.assets.compile = false
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.log_tags = [:request_id]
  config.cache_store = :memory_store
  config.active_storage.service = :local
  config.force_ssl = ENV.fetch("RAILS_FORCE_SSL", "true") == "true"
  config.assume_ssl = true
  config.secret_key_base = ENV.fetch("SECRET_KEY_BASE")
end
