lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
 spec.name    = "fluent-plugin-griddb"
 spec.version = "1.0.1"
 spec.authors = ["TOSHIBA Digital Solutions Corporation"]
 spec.email   = ["contact@griddb.org"]

 spec.summary       = %q{Put data to GridDB}
 spec.description   = %q{Put data to GridDB server via Put row API}
 spec.homepage      = "https://github.com/griddb/fluent-plugin-griddb"
 spec.license       = "Apache-2.0"

 spec.files         = Dir.glob("{bin,lib}/**/*")
 spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
 spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
 spec.require_paths = ['lib']

 spec.add_development_dependency "bundler", "~> 1.14"
 spec.add_development_dependency "rake", "~> 12.0"
 spec.add_development_dependency "test-unit", "~> 3.0"
 spec.add_runtime_dependency "fluentd", [">= 0.14.10", "< 2"]
end