# frozen_string_literal: true

require_relative "../utilities"
require_relative "../variants"

module BoringAvatars
  module Variants
    module Marble
      extend VariantHelpers

      SIZE = 80
      ELEMENTS = 3
      FIRST_PATH = "M32.414 59.35L50.376 70.5H72.5v-71H33.728L26.5 13.381l19.057 27.08L32.414 59.35z"
      SECOND_PATH = "M22.216 24L0 46.75l14.108 38.129L78 86l-3.081-59.276-22.378 4.005 12.972 20.186-23.35 27.395L22.215 24z"

      module_function

      def render(input:, hash:, ids:)
        properties = Array.new(ELEMENTS) do |index|
          multiplier = index + 1
          {
            color: Utilities.random_color(hash + index, input.colors),
            translate_x: Utilities.unit(hash * multiplier, SIZE / 10, 1),
            translate_y: Utilities.unit(hash * multiplier, SIZE / 10, 2),
            scale: 1.2 + (Utilities.unit(hash * multiplier, SIZE / 20) / 10.0),
            rotate: Utilities.unit(hash * multiplier, 360, 1)
          }
        end

        content = [
          element("rect", { "width" => SIZE, "height" => SIZE, "fill" => properties[0][:color] }),
          element(
            "path",
            {
              "filter" => "url(##{ids[:filter]})",
              "d" => FIRST_PATH,
              "fill" => properties[1][:color],
              "transform" => transform(properties[1], properties[2][:scale])
            }
          ),
          element(
            "path",
            {
              "filter" => "url(##{ids[:filter]})",
              "style" => "mix-blend-mode:overlay",
              "d" => SECOND_PATH,
              "fill" => properties[2][:color],
              "transform" => transform(properties[2], properties[2][:scale])
            }
          )
        ]

        filter = element(
          "filter",
          {
            "id" => ids[:filter],
            "filterUnits" => "userSpaceOnUse",
            "color-interpolation-filters" => "sRGB"
          },
          [
            element("feFlood", { "flood-opacity" => 0, "result" => "BackgroundImageFix" }),
            element(
              "feBlend",
              { "in" => "SourceGraphic", "in2" => "BackgroundImageFix", "result" => "shape" }
            ),
            element(
              "feGaussianBlur",
              { "stdDeviation" => 7, "result" => "effect1_foregroundBlur" }
            )
          ]
        )

        VariantResult.new(size: SIZE, content: content, defs: [filter])
      end

      def transform(property, scale)
        "translate(#{number(property[:translate_x])} #{number(property[:translate_y])}) " \
          "rotate(#{number(property[:rotate])} #{SIZE / 2} #{SIZE / 2}) " \
          "scale(#{number(scale)})"
      end
      private_class_method :transform
    end
  end
end

