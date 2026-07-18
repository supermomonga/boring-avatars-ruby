# frozen_string_literal: true

require_relative "identifier"
require_relative "name_hash"
require_relative "svg/serializer"
require_relative "variants/bauhaus"
require_relative "variants/beam"
require_relative "variants/marble"
require_relative "variants/pixel"
require_relative "variants/ring"
require_relative "variants/sunset"

module BoringAvatars
  module Renderer
    VARIANTS = {
      bauhaus: Variants::Bauhaus,
      beam: Variants::Beam,
      marble: Variants::Marble,
      pixel: Variants::Pixel,
      ring: Variants::Ring,
      sunset: Variants::Sunset
    }.freeze

    module_function

    def call(input)
      prefix = Identifier.call(input)
      ids = {
        mask: "#{prefix}-mask",
        filter: "#{prefix}-filter",
        gradient_0: "#{prefix}-gradient-0",
        gradient_1: "#{prefix}-gradient-1"
      }.freeze
      hash = NameHash.call(input.name)
      result = VARIANTS.fetch(input.variant).render(input: input, hash: hash, ids: ids)

      Svg::Serializer.call(root_element(input, result, ids))
    end

    def root_element(input, result, ids)
      root_attributes = {
        "viewBox" => "0 0 #{result.size} #{result.size}",
        "fill" => "none",
        "role" => "img",
        "xmlns" => "http://www.w3.org/2000/svg",
        "width" => input.size,
        "height" => input.size
      }.merge(input.attributes)

      children = []
      children << Svg::Element.new(name: "title", children: [input.name]) if input.title
      children << mask_element(input, result, ids[:mask])
      children << Svg::Element.new(
        name: "g",
        attributes: { "mask" => "url(##{ids[:mask]})" },
        children: result.content
      )
      unless result.defs.empty?
        children << Svg::Element.new(name: "defs", children: result.defs)
      end

      Svg::Element.new(name: "svg", attributes: root_attributes, children: children)
    end
    private_class_method :root_element

    def mask_element(input, result, mask_id)
      attributes = {
        "id" => mask_id,
        "maskUnits" => "userSpaceOnUse",
        "x" => 0,
        "y" => 0,
        "width" => result.size,
        "height" => result.size
      }.merge(result.mask_attributes)
      rectangle = Svg::Element.new(
        name: "rect",
        attributes: {
          "width" => result.size,
          "height" => result.size,
          "rx" => input.square ? nil : result.size * 2,
          "fill" => "#FFFFFF"
        }
      )

      Svg::Element.new(name: "mask", attributes: attributes, children: [rectangle])
    end
    private_class_method :mask_element
  end
  private_constant :Renderer
end

