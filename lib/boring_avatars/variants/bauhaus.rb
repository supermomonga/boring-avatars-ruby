# frozen_string_literal: true

require_relative "../utilities"
require_relative "../variants"

module BoringAvatars
  module Variants
    module Bauhaus
      extend VariantHelpers

      SIZE = 80
      ELEMENTS = 4

      module_function

      def render(input:, hash:, ids:)
        properties = Array.new(ELEMENTS) do |index|
          multiplier = index + 1
          {
            color: Utilities.random_color(hash + index, input.colors),
            translate_x: Utilities.unit(hash * multiplier, (SIZE / 2) - (index + 17), 1),
            translate_y: Utilities.unit(hash * multiplier, (SIZE / 2) - (index + 17), 2),
            rotate: Utilities.unit(hash * multiplier, 360),
            square: Utilities.boolean(hash, 2)
          }
        end

        content = [
          element("rect", { "width" => SIZE, "height" => SIZE, "fill" => properties[0][:color] }),
          element(
            "rect",
            {
              "x" => (SIZE - 60) / 2,
              "y" => (SIZE - 20) / 2,
              "width" => SIZE,
              "height" => properties[1][:square] ? SIZE : SIZE / 8,
              "fill" => properties[1][:color],
              "transform" => transform(properties[1])
            }
          ),
          element(
            "circle",
            {
              "cx" => SIZE / 2,
              "cy" => SIZE / 2,
              "fill" => properties[2][:color],
              "r" => SIZE / 5,
              "transform" => "translate(#{number(properties[2][:translate_x])} #{number(properties[2][:translate_y])})"
            }
          ),
          element(
            "line",
            {
              "x1" => 0,
              "y1" => SIZE / 2,
              "x2" => SIZE,
              "y2" => SIZE / 2,
              "stroke-width" => 2,
              "stroke" => properties[3][:color],
              "transform" => transform(properties[3])
            }
          )
        ]

        VariantResult.new(size: SIZE, content: content)
      end

      def transform(property)
        "translate(#{number(property[:translate_x])} #{number(property[:translate_y])}) " \
          "rotate(#{number(property[:rotate])} #{SIZE / 2} #{SIZE / 2})"
      end
      private_class_method :transform
    end
  end
end

