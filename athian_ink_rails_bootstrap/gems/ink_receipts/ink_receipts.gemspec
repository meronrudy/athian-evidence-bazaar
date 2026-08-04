Gem::Specification.new do |spec|
  spec.name = "ink_receipts"
  spec.version = "0.1.0"
  spec.summary = "Athian INK receipt trust-boundary facade"
  spec.authors = ["Athian demo"]
  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 3.1"

  spec.add_dependency "rubyzip", "~> 2.3"
end
