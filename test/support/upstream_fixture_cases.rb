# frozen_string_literal: true

module UpstreamFixtureCases
  UPSTREAM_SHA = "d0ff2582a8921b643a89de4a4912be28938a828b"
  PACKAGE_VERSION = "2.0.4"
  VARIANTS = %w[marble beam pixel sunset ring bauhaus].freeze
  DEFAULT_COLORS = ["#92A1C6", "#146A7C", "#F0AB3D", "#C271B4", "#C20D90"].freeze
  LONG_NAME = Array.new(32, "Ada Lovelace").join(" ").freeze

  CASES = [
    { id: "default", name: "Maria Mitchell", options: {} },
    { id: "square", name: "Maria Mitchell", options: { square: true } },
    { id: "title", name: "Maria Mitchell", options: { title: true } },
    { id: "palette-one", name: "Maria Mitchell", options: { colors: ["#123456"] } },
    { id: "palette-two", name: "Maria Mitchell", options: { colors: ["#000000", "#FFFFFF"] } },
    {
      id: "palette-five",
      name: "Maria Mitchell",
      options: { colors: ["#112233", "#445566", "#778899", "#AABBCC", "#DDEEFF"] }
    },
    { id: "size-integer", name: "Maria Mitchell", options: { size: 72 } },
    { id: "size-float", name: "Maria Mitchell", options: { size: 37.5 } },
    { id: "size-string", name: "Maria Mitchell", options: { size: "3.5rem" } },
    { id: "ascii-neighbor", name: "Maria Mitchel", options: {} },
    { id: "long-name", name: LONG_NAME, options: {} },
    { id: "empty-name", name: "", options: {} },
    { id: "japanese", name: "日本語", options: {} },
    { id: "emoji", name: "😀", options: {} },
    { id: "unicode-composed", name: "é", options: {} },
    { id: "unicode-decomposed", name: "e\u0301", options: {} },
    { id: "escaped-title", name: %(<Admin & "Owner">), options: { title: true } }
  ].map do |fixture_case|
    fixture_case[:options].freeze
    fixture_case.freeze
  end.freeze

  module_function

  def fixtures
    CASES.product(VARIANTS).map do |fixture_case, variant|
      {
        id: "#{fixture_case.fetch(:id)}--#{variant}",
        case_id: fixture_case.fetch(:id),
        variant: variant
      }.freeze
    end.freeze
  end
end
