# frozen_string_literal: true

require_relative "../utilities"
require_relative "../variants"

module BoringAvatars
  module Variants
    module Sunset
      extend VariantHelpers

      SIZE = 80
      ELEMENTS = 4

      module_function

      def render(input:, hash:, ids:)
        colors = Array.new(ELEMENTS) { |index| Utilities.random_color(hash + index, input.colors) }
        content = [
          element(
            "path",
            { "fill" => "url(##{ids[:gradient_0]})", "d" => "M0 0h80v40H0z" }
          ),
          element(
            "path",
            { "fill" => "url(##{ids[:gradient_1]})", "d" => "M0 40h80v40H0z" }
          )
        ]
        defs = [
          gradient(ids[:gradient_0], 0, SIZE / 2, colors[0], colors[1]),
          gradient(ids[:gradient_1], SIZE / 2, SIZE, colors[2], colors[3])
        ]

        VariantResult.new(size: SIZE, content: content, defs: defs)
      end

      def gradient(id, y1, y2, start_color, end_color)
        element(
          "linearGradient",
          {
            "id" => id,
            "x1" => SIZE / 2,
            "y1" => y1,
            "x2" => SIZE / 2,
            "y2" => y2,
            "gradientUnits" => "userSpaceOnUse"
          },
          [
            element("stop", { "stop-color" => start_color }),
            element("stop", { "offset" => 1, "stop-color" => end_color })
          ]
        )
      end
      private_class_method :gradient
    end
  end
end

