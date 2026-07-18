# frozen_string_literal: true

module BoringAvatars
  module Utilities
    module_function

    def digit(number, position)
      (number / (10**position)).floor % 10
    end

    def boolean(number, position)
      digit(number, position).even?
    end

    def unit(number, range, position = nil)
      value = number % range
      position && !position.zero? && digit(number, position).even? ? -value : value
    end

    def random_color(number, colors)
      colors[number % colors.length]
    end

    def contrast(color)
      red = color[1, 2].to_i(16)
      green = color[3, 2].to_i(16)
      blue = color[5, 2].to_i(16)
      yiq = ((red * 299) + (green * 587) + (blue * 114)) / 1000.0

      yiq >= 128 ? "#000000" : "#FFFFFF"
    end
  end
end

