# frozen_string_literal: true

require_relative "svg/serializer"

module BoringAvatars
  DEFAULT_COLORS = ["#92A1C6", "#146A7C", "#F0AB3D", "#C271B4", "#C20D90"].map(&:freeze).freeze
  VARIANTS = %w[marble beam pixel sunset ring bauhaus].freeze
  COLOR_PATTERN = /\A#[0-9A-Fa-f]{6}\z/
  SIZE_PATTERN = /\A(?<number>(?:\d+(?:\.\d+)?)|(?:\.\d+))(?<unit>px|em|rem|%|vw|vh|vmin|vmax)?\z/
  ID_PREFIX_PATTERN = /\A[A-Za-z][A-Za-z0-9_-]{0,63}\z/
  ATTRIBUTE_PATTERN = /\A(?:id|class|lang|tabindex|focusable|(?:aria|data)-[a-z0-9]+(?:-[a-z0-9]+)*)\z/

  Input = Data.define(:name, :variant, :colors, :size, :square, :title, :id_prefix, :attributes) do
    def initialize(
      name:,
      variant: :marble,
      colors: DEFAULT_COLORS,
      size: "40px",
      square: false,
      title: false,
      id_prefix: nil,
      attributes: {}
    )
      super(
        name: normalize_string(name, "name"),
        variant: normalize_variant(variant),
        colors: normalize_colors(colors),
        size: normalize_size(size),
        square: normalize_boolean(square, "square"),
        title: normalize_boolean(title, "title"),
        id_prefix: normalize_id_prefix(id_prefix),
        attributes: normalize_attributes(attributes)
      )
    end

    private

    def normalize_string(value, label)
      raise ArgumentError, "#{label} must be a String" unless value.is_a?(String)

      normalized = value.encode(Encoding::UTF_8)
      unless Svg::Serializer.valid_xml_string?(normalized)
        raise ArgumentError, "#{label} contains characters forbidden by XML 1.0"
      end

      normalized.freeze
    rescue EncodingError => error
      raise ArgumentError, "#{label} must be convertible to UTF-8: #{error.message}"
    end

    def normalize_variant(value)
      variant = case value
                when String then normalize_string(value, "variant")
                when Symbol then normalize_string(value.to_s, "variant")
                else raise ArgumentError, "variant must be a String or Symbol"
                end
      raise ArgumentError, "unknown variant: #{variant.inspect}" unless VARIANTS.include?(variant)

      variant.to_sym
    end

    def normalize_colors(value)
      raise ArgumentError, "colors must be a non-empty Array" unless value.is_a?(Array) && !value.empty?

      value.map.with_index do |color, index|
        normalized = normalize_string(color, "colors[#{index}]")
        raise ArgumentError, "colors[#{index}] must use #RRGGBB format" unless COLOR_PATTERN.match?(normalized)

        normalized
      end.freeze
    end

    def normalize_size(value)
      case value
      when Integer
        raise ArgumentError, "size must be greater than zero" unless value.positive?
        value
      when Float
        raise ArgumentError, "size must be finite and greater than zero" unless value.finite? && value.positive?
        value
      when String
        normalized = normalize_string(value, "size")
        match = SIZE_PATTERN.match(normalized)
        unless match && match[:number].to_f.positive?
          raise ArgumentError, "size has an unsupported format"
        end
        normalized
      else
        raise ArgumentError, "size must be an Integer, Float, or String"
      end
    end

    def normalize_boolean(value, label)
      return value if value.equal?(true) || value.equal?(false)

      raise ArgumentError, "#{label} must be true or false"
    end

    def normalize_id_prefix(value)
      return if value.nil?

      normalized = normalize_string(value, "id_prefix")
      raise ArgumentError, "id_prefix has an unsupported format" unless ID_PREFIX_PATTERN.match?(normalized)

      normalized
    end

    def normalize_attributes(value)
      raise ArgumentError, "attributes must be a Hash" unless value.is_a?(Hash)

      normalized = {}
      seen = {}
      value.each do |name, attribute_value|
        normalized_name = normalize_attribute_name(name)
        raise ArgumentError, "duplicate SVG attribute: #{normalized_name}" if seen.key?(normalized_name)

        seen[normalized_name] = true

        next if attribute_value.nil?

        normalized[normalized_name.freeze] = normalize_attribute_value(attribute_value, normalized_name)
      end
      normalized.sort.to_h.freeze
    end

    def normalize_attribute_name(value)
      name = case value
             when String then normalize_string(value, "SVG attribute name")
             when Symbol then normalize_string(value.to_s.tr("_", "-"), "SVG attribute name")
             else raise ArgumentError, "SVG attribute names must be String or Symbol"
             end
      raise ArgumentError, "unsupported SVG attribute: #{name}" unless ATTRIBUTE_PATTERN.match?(name)

      name
    end

    def normalize_attribute_value(value, name)
      case value
      when String
        normalize_string(value, "attribute #{name}")
      when Numeric
        if value.respond_to?(:finite?) && !value.finite?
          raise ArgumentError, "attribute #{name} must be finite"
        end
        value
      when true, false
        value
      else
        raise ArgumentError, "attribute #{name} has an unsupported value type"
      end
    end
  end
  private_constant :Input, :DEFAULT_COLORS, :VARIANTS, :COLOR_PATTERN, :SIZE_PATTERN,
                   :ID_PREFIX_PATTERN, :ATTRIBUTE_PATTERN
end
