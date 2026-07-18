# frozen_string_literal: true

module BoringAvatars
  module Svg
    Element = Data.define(:name, :attributes, :children) do
      def initialize(name:, attributes: {}, children: [])
        super(
          name: name.to_s.freeze,
          attributes: attributes.reject { |_key, value| value.nil? }.freeze,
          children: children.freeze
        )
      end
    end
  end
end

