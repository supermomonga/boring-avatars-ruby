# frozen_string_literal: true

require "securerandom"

module BoringAvatars
  module Bindings
    module Rails
      module ViewHelper
        UNSPECIFIED = Object.new.freeze

        def boring_avatar(
          name,
          variant: :marble,
          colors: UNSPECIFIED,
          size: "40px",
          square: false,
          title: false,
          id_prefix: nil,
          **svg_attributes
        )
          prefix = id_prefix || "ba-#{SecureRandom.hex(10)}"
          options = {
            variant: variant,
            size: size,
            square: square,
            title: title,
            id_prefix: prefix,
            attributes: normalize_boring_avatar_attributes(svg_attributes)
          }
          options[:colors] = colors unless colors.equal?(UNSPECIFIED)

          svg = BoringAvatars.generate(name, **options)
          svg.html_safe
        end

        private

        def normalize_boring_avatar_attributes(attributes)
          normalized = {}
          attributes.each do |name, value|
            next if value.nil?

            case name.to_s
            when "class"
              store_boring_avatar_attribute(normalized, "class", normalize_boring_avatar_class(value))
            when "data", "aria"
              expand_boring_avatar_attributes(normalized, name.to_s, value)
            else
              normalized_name = normalize_boring_avatar_attribute_name(name)
              store_boring_avatar_attribute(normalized, normalized_name, value)
            end
          end
          normalized
        end

        def normalize_boring_avatar_class(value)
          return value if value.is_a?(String)

          unless value.is_a?(Array) && value.all? { |item| item.is_a?(String) && !item.empty? }
            raise ArgumentError, "class must be a String or an Array of non-empty Strings"
          end

          value.join(" ")
        end

        def expand_boring_avatar_attributes(normalized, prefix, value)
          raise ArgumentError, "#{prefix} must be a Hash" unless value.is_a?(Hash)

          value.each do |nested_name, nested_value|
            suffix = normalize_boring_avatar_nested_attribute_name(nested_name)
            store_boring_avatar_attribute(normalized, "#{prefix}-#{suffix}", nested_value)
          end
        end

        def normalize_boring_avatar_nested_attribute_name(value)
          case value
          when String, Symbol
            value.to_s.tr("_", "-")
          else
            raise ArgumentError, "nested SVG attribute names must be String or Symbol"
          end
        end

        def normalize_boring_avatar_attribute_name(value)
          case value
          when String
            value
          when Symbol
            value.to_s.tr("_", "-")
          else
            raise ArgumentError, "SVG attribute names must be String or Symbol"
          end
        end

        def store_boring_avatar_attribute(attributes, name, value)
          raise ArgumentError, "duplicate SVG attribute: #{name}" if attributes.key?(name)

          attributes[name] = value
        end

        private_constant :UNSPECIFIED
      end
    end
  end
end
