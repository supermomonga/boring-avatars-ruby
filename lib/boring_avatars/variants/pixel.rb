# frozen_string_literal: true

require_relative "../utilities"
require_relative "../variants"

module BoringAvatars
  module Variants
    module Pixel
      extend VariantHelpers

      SIZE = 80
      ELEMENTS = 64
      TOP_ROW_X = [0, 20, 40, 60, 10, 30, 50, 70].freeze
      COLUMN_X = [0, 20, 40, 60, 10, 30, 50, 70].freeze
      Y_COORDINATES = (10..70).step(10).to_a.freeze
      COORDINATES = (
        TOP_ROW_X.map { |x| [x, 0] } +
        COLUMN_X.flat_map { |x| Y_COORDINATES.map { |y| [x, y] } }
      ).freeze

      module_function

      def render(input:, hash:, ids:)
        colors = Array.new(ELEMENTS) do |index|
          Utilities.random_color(hash % (index + 1), input.colors)
        end
        content = COORDINATES.each_with_index.map do |(x, y), index|
          element(
            "rect",
            {
              "x" => x.zero? ? nil : x,
              "y" => y.zero? ? nil : y,
              "width" => 10,
              "height" => 10,
              "fill" => colors[index]
            }
          )
        end

        VariantResult.new(
          size: SIZE,
          content: content,
          mask_attributes: { "mask-type" => "alpha" }
        )
      end
    end
  end
end

