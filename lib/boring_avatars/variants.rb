# frozen_string_literal: true

require_relative "svg/element"
require_relative "svg/value"

module BoringAvatars
  VariantResult = Data.define(:size, :content, :defs, :mask_attributes) do
    def initialize(size:, content:, defs: [], mask_attributes: {})
      super(
        size: size,
        content: content.freeze,
        defs: defs.freeze,
        mask_attributes: mask_attributes.freeze
      )
    end
  end
  private_constant :VariantResult

  module VariantHelpers
    private

    def element(name, attributes = {}, children = [])
      Svg::Element.new(name: name, attributes: attributes, children: children)
    end

    def number(value)
      Svg::Value.number(value)
    end
  end
  private_constant :VariantHelpers
end

