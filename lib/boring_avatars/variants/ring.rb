# frozen_string_literal: true

require_relative "../utilities"
require_relative "../variants"

module BoringAvatars
  module Variants
    module Ring
      extend VariantHelpers

      SIZE = 90
      COLORS = 5
      PATHS = [
        "M0 0h90v45H0z",
        "M0 45h90v45H0z",
        "M83 45a38 38 0 00-76 0h76z",
        "M83 45a38 38 0 01-76 0h76z",
        "M77 45a32 32 0 10-64 0h64z",
        "M77 45a32 32 0 11-64 0h64z",
        "M71 45a26 26 0 00-52 0h52z",
        "M71 45a26 26 0 01-52 0h52z"
      ].freeze

      module_function

      def render(input:, hash:, ids:)
        shuffled = Array.new(COLORS) { |index| Utilities.random_color(hash + index, input.colors) }
        colors = [
          shuffled[0], shuffled[1], shuffled[1], shuffled[2], shuffled[2],
          shuffled[3], shuffled[3], shuffled[0], shuffled[4]
        ]
        content = PATHS.each_with_index.map do |path, index|
          element("path", { "d" => path, "fill" => colors[index] })
        end
        content << element("circle", { "cx" => 45, "cy" => 45, "r" => 23, "fill" => colors[8] })

        VariantResult.new(size: SIZE, content: content)
      end
    end
  end
end

