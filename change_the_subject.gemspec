# frozen_string_literal: true

require_relative "lib/change_the_subject/version"

Gem::Specification.new do |spec|
  spec.name          = "change_the_subject"
  spec.version       = ChangeTheSubject::VERSION
  spec.authors       = ["Max Kadel", "Anna Headley", "Trey Pendragon", "Eliot Jordan"]
  spec.email         = ["digital-library@princeton.libanswers.com"]

  spec.summary       = "Provides configuration and utilities for replacing archaic subject terms with preferred subject terms"
  spec.homepage      = "https://github.com/pulibrary/change_the_subject"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "yaml"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "1.72"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "simplecov"
end
