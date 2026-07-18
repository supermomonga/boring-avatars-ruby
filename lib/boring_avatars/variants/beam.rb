# frozen_string_literal: true

require_relative "../utilities"
require_relative "../variants"

module BoringAvatars
  module Variants
    module Beam
      extend VariantHelpers

      SIZE = 36

      module_function

      def render(input:, hash:, ids:)
        data = generate_data(hash, input.colors)
        content = [
          element("rect", { "width" => SIZE, "height" => SIZE, "fill" => data[:background_color] }),
          element(
            "rect",
            {
              "x" => 0,
              "y" => 0,
              "width" => SIZE,
              "height" => SIZE,
              "transform" => wrapper_transform(data),
              "fill" => data[:wrapper_color],
              "rx" => data[:is_circle] ? SIZE : SIZE / 6
            }
          ),
          element("g", { "transform" => face_transform(data) }, face_elements(data))
        ]

        VariantResult.new(size: SIZE, content: content)
      end

      def generate_data(hash, colors)
        wrapper_color = Utilities.random_color(hash, colors)
        pre_translate_x = Utilities.unit(hash, 10, 1)
        wrapper_translate_x = pre_translate_x < 5 ? pre_translate_x + (SIZE / 9) : pre_translate_x
        pre_translate_y = Utilities.unit(hash, 10, 2)
        wrapper_translate_y = pre_translate_y < 5 ? pre_translate_y + (SIZE / 9) : pre_translate_y

        {
          wrapper_color: wrapper_color,
          face_color: Utilities.contrast(wrapper_color),
          background_color: Utilities.random_color(hash + 13, colors),
          wrapper_translate_x: wrapper_translate_x,
          wrapper_translate_y: wrapper_translate_y,
          wrapper_rotate: Utilities.unit(hash, 360),
          wrapper_scale: 1 + (Utilities.unit(hash, SIZE / 12) / 10.0),
          is_mouth_open: Utilities.boolean(hash, 2),
          is_circle: Utilities.boolean(hash, 1),
          eye_spread: Utilities.unit(hash, 5),
          mouth_spread: Utilities.unit(hash, 3),
          face_rotate: Utilities.unit(hash, 10, 3),
          face_translate_x: wrapper_translate_x > SIZE / 6 ? wrapper_translate_x / 2.0 : Utilities.unit(hash, 8, 1),
          face_translate_y: wrapper_translate_y > SIZE / 6 ? wrapper_translate_y / 2.0 : Utilities.unit(hash, 7, 2)
        }
      end
      private_class_method :generate_data

      def wrapper_transform(data)
        "translate(#{number(data[:wrapper_translate_x])} #{number(data[:wrapper_translate_y])}) " \
          "rotate(#{number(data[:wrapper_rotate])} #{SIZE / 2} #{SIZE / 2}) " \
          "scale(#{number(data[:wrapper_scale])})"
      end
      private_class_method :wrapper_transform

      def face_transform(data)
        "translate(#{number(data[:face_translate_x])} #{number(data[:face_translate_y])}) " \
          "rotate(#{number(data[:face_rotate])} #{SIZE / 2} #{SIZE / 2})"
      end
      private_class_method :face_transform

      def face_elements(data)
        mouth_y = 19 + data[:mouth_spread]
        mouth = if data[:is_mouth_open]
                  element(
                    "path",
                    {
                      "d" => "M15 #{number(mouth_y)}c2 1 4 1 6 0",
                      "stroke" => data[:face_color],
                      "fill" => "none",
                      "stroke-linecap" => "round"
                    }
                  )
                else
                  element(
                    "path",
                    {
                      "d" => "M13,#{number(mouth_y)} a1,0.75 0 0,0 10,0",
                      "fill" => data[:face_color]
                    }
                  )
                end

        [
          mouth,
          element(
            "rect",
            {
              "x" => 14 - data[:eye_spread],
              "y" => 14,
              "width" => 1.5,
              "height" => 2,
              "rx" => 1,
              "stroke" => "none",
              "fill" => data[:face_color]
            }
          ),
          element(
            "rect",
            {
              "x" => 20 + data[:eye_spread],
              "y" => 14,
              "width" => 1.5,
              "height" => 2,
              "rx" => 1,
              "stroke" => "none",
              "fill" => data[:face_color]
            }
          )
        ]
      end
      private_class_method :face_elements
    end
  end
end

