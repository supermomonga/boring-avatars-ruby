# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/svg_canonicalizer"
require_relative "support/upstream_fixture_cases"
require "json"

class UpstreamParityTest < Minitest::Test
  FIXTURE_ROOT = File.expand_path(
    "fixtures/upstream/#{UpstreamFixtureCases::UPSTREAM_SHA}",
    __dir__
  )

  def test_fixture_metadata_is_pinned
    metadata = JSON.parse(File.read(File.join(FIXTURE_ROOT, "metadata.json")))

    assert_equal UpstreamFixtureCases::UPSTREAM_SHA, metadata.fetch("commit")
    assert_equal UpstreamFixtureCases::PACKAGE_VERSION, metadata.fetch("package_version")
    assert_equal UpstreamFixtureCases::DEFAULT_COLORS, metadata.fetch("default_colors")
    assert_equal UpstreamFixtureCases::VARIANTS, metadata.fetch("variants")
    assert_equal JSON.parse(JSON.generate(UpstreamFixtureCases::CASES)), metadata.fetch("cases")
    assert_equal UpstreamFixtureCases.fixtures.length, metadata.fetch("fixture_count")
  end

  def test_normalized_svg_dom_matches_pinned_react_output
    fixtures = load_fixtures
    expected_ids = UpstreamFixtureCases.fixtures.map { |fixture| fixture.fetch(:id) }

    assert_equal expected_ids.sort, fixtures.keys.sort

    UpstreamFixtureCases::CASES.each do |fixture_case|
      UpstreamFixtureCases::VARIANTS.each do |variant|
        fixture_id = "#{fixture_case.fetch(:id)}--#{variant}"
        upstream = fixtures.fetch(fixture_id).fetch("svg")
        ruby = BoringAvatars.generate(
          fixture_case.fetch(:name),
          variant: variant,
          id_prefix: "ruby-reference",
          **fixture_case.fetch(:options)
        )

        assert_equal SvgCanonicalizer.call(upstream), SvgCanonicalizer.call(ruby), fixture_id
      end
    end
  end

  private

  def load_fixtures
    path = File.join(FIXTURE_ROOT, "fixtures.jsonl")
    File.foreach(path, chomp: true).to_h do |line|
      fixture = JSON.parse(line)
      [fixture.fetch("id"), fixture]
    end
  end
end
