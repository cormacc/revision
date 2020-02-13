lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "revision/version"

Gem::Specification.new do |spec|
  spec.name          = "revision"
  spec.version       = Revision::VERSION
  spec.authors       = ["Cormac Cannon"]
  spec.licenses      = ['MIT']

  spec.summary       = %q{Language-agnostic revision management tool}
  spec.description   = %q{Updates project revision identifiers in software source files and associated change log. Can also build and package project archives as a zip and optionally commit, tag and push to a Git repo.}
  spec.homepage    = 'https://rubygems.org/gems/revision'
  spec.metadata    = { "source_code_uri" => "https://github.com/cormacc/revision" }

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^#{spec.bindir}/}) { |f| File.basename(f) }

  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'thor', '~> 1.0'
  spec.add_runtime_dependency 'rubyzip', '~> 2.0'

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
end
