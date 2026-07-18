# frozen_string_literal: true

require_relative "lib/boring_avatars/version"

Gem::Specification.new do |spec|
  spec.name = "boring_avatars"
  spec.version = BoringAvatars::VERSION
  spec.authors = ["boring_avatars contributors"]

  spec.summary = "Generate deterministic Boring Avatars SVGs in Ruby"
  spec.description = "A Ruby port of Boring Avatars with a framework-independent SVG core and an opt-in Rails View Helper."
  spec.homepage = "https://github.com/supermomonga/boring-avatars-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3"

  spec.metadata = {
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "changelog_uri" => "#{spec.homepage}/releases",
    "rubygems_mfa_required" => "true",
    "source_code_uri" => spec.homepage
  }

  spec.files = Dir[
    "lib/**/*",
    "rbi/**/*",
    "sig/**/*",
    "docs/**/*",
    "LICENSE",
    "README.md",
    "THIRD_PARTY_NOTICES.md"
  ].select { |path| File.file?(path) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", ">= 5.20"
  spec.add_development_dependency "nokogiri", ">= 1.16"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rbs", ">= 4.0"
  spec.add_development_dependency "sorbet", ">= 0.6"
  spec.add_development_dependency "steep", ">= 1.10"
end
