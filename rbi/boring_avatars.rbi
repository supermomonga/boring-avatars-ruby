# typed: true

module BoringAvatars
  Variant = T.type_alias { T.any(String, Symbol) }
  Size = T.type_alias { T.any(Integer, Float, String) }
  AttributeKey = T.type_alias { T.any(String, Symbol) }
  AttributeValue = T.type_alias { T.any(String, Numeric, T::Boolean, NilClass) }
  RailsAttributeValue = T.type_alias do
    T.any(
      AttributeValue,
      T::Array[String],
      T::Hash[AttributeKey, AttributeValue]
    )
  end

  VERSION = T.let(T.unsafe(nil), String)

  sig do
    params(
      name: String,
      variant: Variant,
      colors: T::Array[String],
      size: Size,
      square: T::Boolean,
      title: T::Boolean,
      id_prefix: T.nilable(String),
      attributes: T::Hash[AttributeKey, AttributeValue]
    ).returns(String)
  end
  def self.generate(
    name,
    variant: T.unsafe(nil),
    colors: T.unsafe(nil),
    size: T.unsafe(nil),
    square: T.unsafe(nil),
    title: T.unsafe(nil),
    id_prefix: T.unsafe(nil),
    attributes: T.unsafe(nil)
  ); end

  module Bindings
    module Rails
      module ViewHelper
        sig do
          params(
            name: String,
            variant: Variant,
            colors: T::Array[String],
            size: Size,
            square: T::Boolean,
            title: T::Boolean,
            id_prefix: T.nilable(String),
            svg_attributes: RailsAttributeValue
          ).returns(String)
        end
        def boring_avatar(
          name,
          variant: T.unsafe(nil),
          colors: T.unsafe(nil),
          size: T.unsafe(nil),
          square: T.unsafe(nil),
          title: T.unsafe(nil),
          id_prefix: T.unsafe(nil),
          **svg_attributes
        ); end
      end
    end
  end
end

