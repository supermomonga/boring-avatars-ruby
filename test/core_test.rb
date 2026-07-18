# frozen_string_literal: true

require_relative "test_helper"

class CoreTest < Minitest::Test
  DEFAULT_COLORS = ["#92A1C6", "#146A7C", "#F0AB3D", "#C271B4", "#C20D90"].freeze
  VIEW_BOXES = {
    marble: "0 0 80 80",
    beam: "0 0 36 36",
    pixel: "0 0 80 80",
    sunset: "0 0 80 80",
    ring: "0 0 90 90",
    bauhaus: "0 0 80 80"
  }.freeze

  def test_generates_well_formed_svg_for_every_variant
    VIEW_BOXES.each do |variant, view_box|
      document = parse_svg(BoringAvatars.generate("Maria Mitchell", variant: variant))
      root = document.root

      assert_equal "svg", root.name, variant
      assert_equal view_box, root["viewBox"], variant
      assert_equal "40px", root["width"], variant
      assert_equal "40px", root["height"], variant
      assert_equal "img", root["role"], variant
      assert_equal 1, elements(document, "mask").length, variant
    end
  end

  def test_output_is_deterministic_by_default
    first = BoringAvatars.generate("Maria Mitchell", variant: :sunset)
    second = BoringAvatars.generate("Maria Mitchell", variant: :sunset)

    assert_equal first, second
    assert_match(/id="ba-[0-9a-f]{20}-mask"/, first)
  end

  def test_defining_inputs_change_the_deterministic_id
    base = parse_svg(BoringAvatars.generate("Maria Mitchell", variant: :sunset))
    changed_name = parse_svg(BoringAvatars.generate("Grace Hopper", variant: :sunset))
    changed_colors = parse_svg(
      BoringAvatars.generate("Maria Mitchell", variant: :sunset, colors: ["#000000", "#FFFFFF"])
    )
    changed_square = parse_svg(BoringAvatars.generate("Maria Mitchell", variant: :sunset, square: true))

    ids = [base, changed_name, changed_colors, changed_square].map { |document| internal_ids(document).first }
    assert_equal ids.length, ids.uniq.length
  end

  def test_non_defining_inputs_do_not_change_the_internal_id
    base = parse_svg(BoringAvatars.generate("Maria Mitchell", variant: :marble))
    changed = parse_svg(
      BoringAvatars.generate(
        "Maria Mitchell",
        variant: :marble,
        size: 80,
        title: true,
        attributes: { class: "avatar" }
      )
    )

    assert_equal internal_ids(base), internal_ids(changed)
  end

  def test_explicit_id_prefix_is_used_for_all_fragment_references
    document = parse_svg(
      BoringAvatars.generate("Maria Mitchell", variant: :marble, id_prefix: "profile-avatar")
    )
    ids = internal_ids(document)

    assert_equal ["profile-avatar-mask", "profile-avatar-filter"], ids
    assert_equal "url(#profile-avatar-mask)", elements(document, "g").first["mask"]
    assert elements(document, "path").all? { |path| path["filter"] == "url(#profile-avatar-filter)" }
  end

  def test_title_and_attributes_are_escaped_by_the_serializer
    document = parse_svg(
      BoringAvatars.generate(
        %(<Admin & "Owner">),
        title: true,
        attributes: {
          class: %("><script>alert(1)</script>),
          :"aria-label" => %(A & B)
        }
      )
    )

    assert_equal %(<Admin & "Owner">), elements(document, "title").first.text
    assert_equal %("><script>alert(1)</script>), document.root["class"]
    assert_equal "A & B", document.root["aria-label"]
    assert_empty elements(document, "script")
  end

  def test_square_omits_mask_radius
    round = parse_svg(BoringAvatars.generate("name"))
    square = parse_svg(BoringAvatars.generate("name", square: true))

    assert_equal "160", elements(round, "mask").first.at_xpath("./*[local-name()='rect']")["rx"]
    assert_nil elements(square, "mask").first.at_xpath("./*[local-name()='rect']")["rx"]
  end

  def test_variant_specific_structure
    pixel = parse_svg(BoringAvatars.generate("name", variant: :pixel))
    sunset = parse_svg(BoringAvatars.generate("name", variant: :sunset))
    ring = parse_svg(BoringAvatars.generate("name", variant: :ring))
    marble = parse_svg(BoringAvatars.generate("name", variant: :marble))

    pixel_group = elements(pixel, "g").first
    assert_equal 64, pixel_group.xpath("./*[local-name()='rect']").length
    assert_equal "alpha", elements(pixel, "mask").first["mask-type"]
    assert_equal 2, elements(sunset, "linearGradient").length
    assert_equal 8, elements(ring, "path").length
    assert_equal 1, elements(ring, "circle").length
    assert_equal "7", elements(marble, "feGaussianBlur").first["stdDeviation"]
  end

  def test_every_fragment_reference_resolves_to_a_unique_local_id
    VIEW_BOXES.each_key do |variant|
      document = parse_svg(BoringAvatars.generate("Maria Mitchell", variant: variant))
      ids = internal_ids(document)
      references = document.xpath("//*[@*]").flat_map do |node|
        node.attribute_nodes.filter_map { |attribute| attribute.value[/url\(#([^)]+)\)/, 1] }
      end

      assert_equal ids.uniq, ids, variant
      references.each { |reference| assert_includes ids, reference, "#{variant}: #{reference}" }
    end
  end

  def test_accepts_string_variants_and_one_color_palette
    svg = BoringAvatars.generate("name", variant: "ring", colors: ["#abcdef"])

    assert_equal ["#abcdef"], parse_svg(svg).xpath("//*[@fill]").map { |node| node["fill"] }.grep("#abcdef").uniq
  end

  def test_rejects_invalid_inputs
    invalid_calls = [
      -> { BoringAvatars.generate(nil) },
      -> { BoringAvatars.generate("name", variant: :unknown) },
      -> { BoringAvatars.generate("name", variant: :geometric) },
      -> { BoringAvatars.generate("name", colors: []) },
      -> { BoringAvatars.generate("name", colors: ["red"]) },
      -> { BoringAvatars.generate("name", size: 0) },
      -> { BoringAvatars.generate("name", size: Float::NAN) },
      -> { BoringAvatars.generate("name", size: "calc(100%)") },
      -> { BoringAvatars.generate("name", square: nil) },
      -> { BoringAvatars.generate("name", title: 1) },
      -> { BoringAvatars.generate("name", id_prefix: "1 invalid") },
      -> { BoringAvatars.generate("name", attributes: { style: "color:red" }) },
      -> { BoringAvatars.generate("name", attributes: { onload: "alert(1)" }) },
      -> { BoringAvatars.generate("name", attributes: { href: "https://example.com" }) },
      -> { BoringAvatars.generate("name", attributes: { class: Object.new }) },
      -> { BoringAvatars.generate("name", unsupported: true) }
    ]

    invalid_calls.each { |call| assert_raises(ArgumentError, &call) }
  end

  def test_rejects_xml_control_characters
    assert_raises(ArgumentError) { BoringAvatars.generate("name\u0000") }
    assert_raises(ArgumentError) do
      BoringAvatars.generate("name", attributes: { class: "avatar\u0001" })
    end
  end

  def test_nil_attributes_are_omitted_but_normalized_duplicates_raise
    document = parse_svg(BoringAvatars.generate("name", attributes: { class: nil }))
    assert_nil document.root["class"]

    attributes = { class: nil, "class" => "avatar" }
    assert_raises(ArgumentError) { BoringAvatars.generate("name", attributes: attributes) }
  end

  def test_core_does_not_load_rails
    script = <<~RUBY
      require "boring_avatars"
      features = $LOADED_FEATURES.grep(%r{active_support|action_view|bindings/rails})
      abort(features.inspect) unless features.empty?
    RUBY
    _output, error, status = Open3.capture3(
      RbConfig.ruby,
      "-I#{File.expand_path('../lib', __dir__)}",
      "-e",
      script
    )

    assert status.success?, error
  end

  def test_rails_binding_fails_explicitly_without_active_support
    skip "ActiveSupport is present in the Rails matrix" if Gem.loaded_specs.key?("activesupport")

    script = <<~RUBY
      begin
        require "boring_avatars/bindings/rails"
      rescue LoadError => error
        exit(error.path&.include?("active_support") ? 0 : 2)
      end
      exit 1
    RUBY
    _output, error, status = Open3.capture3(
      RbConfig.ruby,
      "--disable-gems",
      "-I#{File.expand_path('../lib', __dir__)}",
      "-e",
      script
    )

    assert status.success?, error
  end
end
