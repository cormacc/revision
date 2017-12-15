lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "revision/version"

Gem::Specification.new do |spec|
  spec.name          = "revision"
  spec.version       = Revision::VERSION
  spec.authors       = ["Cormac Cannon"]
  spec.email         = ["cormac.cannon@neuromoddevices.com"]

  spec.summary       = %q{Language-agnostic revision management tool}
  spec.description   = %q{Updates project revision identifiers in software source files and associated change log. Can also build and package project archives as a zip and optionally commit, tag and push to a Git repo.}
#  spec.homepage      = "TBC"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "http://gems.nmd.ie"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^#{spec.bindir}/}) { |f| File.basename(f) }

  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'thor', '~> 0.19.1'
  spec.add_runtime_dependency 'rubyzip'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
end
