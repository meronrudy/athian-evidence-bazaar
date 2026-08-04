require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module AthianInkEvidencePlane
  class Application < Rails::Application
    config.load_defaults 7.1
    config.autoload_lib(ignore: %w[assets tasks])
    config.time_zone = "UTC"
    config.active_record.default_timezone = :utc
    config.generators.system_tests = nil
  end
end
