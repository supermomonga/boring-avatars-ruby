# frozen_string_literal: true

module BoringAvatars
  module Svg
    module Value
      module_function

      def number(value)
        return "0" if value.zero?
        return value.to_i.to_s if value.is_a?(Float) && value.finite? && value == value.to_i

        value.to_s
      end
    end
  end
end

