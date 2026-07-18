# frozen_string_literal: true

require_relative "element"
require_relative "value"

module BoringAvatars
  module Svg
    module Serializer
      module_function

      def call(element)
        serialize_element(element).force_encoding(Encoding::UTF_8)
      end

      def valid_xml_string?(value)
        value.valid_encoding? && value.codepoints.all? do |codepoint|
          codepoint == 0x09 || codepoint == 0x0A || codepoint == 0x0D ||
            codepoint.between?(0x20, 0xD7FF) ||
            codepoint.between?(0xE000, 0xFFFD) ||
            codepoint.between?(0x10000, 0x10FFFF)
        end
      end

      def escape(value)
        string = value.to_s
        raise ArgumentError, "value contains characters forbidden by XML 1.0" unless valid_xml_string?(string)

        string
          .gsub("&", "&amp;")
          .gsub("<", "&lt;")
          .gsub(">", "&gt;")
          .gsub('"', "&quot;")
          .gsub("'", "&apos;")
      end

      def serialize_element(element)
        attributes = element.attributes.map do |name, value|
          %(#{name}="#{escape(attribute_value(value))}")
        end
        opening = attributes.empty? ? "<#{element.name}" : "<#{element.name} #{attributes.join(' ')}"

        return "#{opening}/>" if element.children.empty?

        content = element.children.map do |child|
          child.is_a?(Element) ? serialize_element(child) : escape(child)
        end.join
        "#{opening}>#{content}</#{element.name}>"
      end
      private_class_method :serialize_element

      def attribute_value(value)
        case value
        when String
          value
        when Numeric
          Value.number(value)
        when true, false
          value.to_s
        else
          raise ArgumentError, "unsupported SVG attribute value: #{value.class}"
        end
      end
      private_class_method :attribute_value
    end
  end
end

