# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/svg_canonicalizer"
require "json"

class UpstreamParityTest < Minitest::Test
  FIXTURE_ROOT = File.expand_path(
    "fixtures/upstream/d0ff2582a8921b643a89de4a4912be28938a828b",
    __dir__
  )
  VARIANTS = %i[marble beam pixel sunset ring bauhaus].freeze

  def test_fixture_metadata_is_pinned
    metadata = JSON.parse(File.read(File.join(FIXTURE_ROOT, "metadata.json")))

    assert_equal "d0ff2582a8921b643a89de4a4912be28938a828b", metadata.fetch("commit")
    assert_equal "2.0.4", metadata.fetch("package_version")
    assert_equal "Maria Mitchell", metadata.fetch("name")
  end

  def test_normalized_svg_dom_matches_pinned_react_output
    VARIANTS.each do |variant|
      upstream = File.read(File.join(FIXTURE_ROOT, "#{variant}.svg"), encoding: Encoding::UTF_8)
      ruby = BoringAvatars.generate("Maria Mitchell", variant: variant, id_prefix: "ruby-reference")

      assert_equal SvgCanonicalizer.call(upstream), SvgCanonicalizer.call(ruby), variant
    end
  end
end
