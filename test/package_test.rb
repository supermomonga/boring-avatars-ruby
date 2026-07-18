# frozen_string_literal: true

require_relative "test_helper"

class PackageTest < Minitest::Test
  def test_gemspec_has_no_rails_runtime_dependencies
    specification = Gem::Specification.load(File.expand_path("../boring_avatars.gemspec", __dir__))

    assert_equal Gem::Requirement.new(">= 3.3"), specification.required_ruby_version
    assert_empty specification.runtime_dependencies
    assert_includes specification.files, "lib/boring_avatars/bindings/rails.rb"
    assert_includes specification.files, "rbi/boring_avatars.rbi"
    assert_includes specification.files, "sig/boring_avatars.rbs"
    assert_includes specification.files, "LICENSE"
    assert_includes specification.files, "THIRD_PARTY_NOTICES.md"
  end
end
