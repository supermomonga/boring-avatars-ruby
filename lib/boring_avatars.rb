# frozen_string_literal: true

require_relative "boring_avatars/version"
require_relative "boring_avatars/input"
require_relative "boring_avatars/renderer"

module BoringAvatars
  class << self
    def generate(
      name,
      variant: :marble,
      colors: DEFAULT_COLORS,
      size: "40px",
      square: false,
      title: false,
      id_prefix: nil,
      attributes: {}
    )
      input = Input.new(
        name: name,
        variant: variant,
        colors: colors,
        size: size,
        square: square,
        title: title,
        id_prefix: id_prefix,
        attributes: attributes
      )
      Renderer.call(input)
    end
  end

  private_constant :Identifier, :NameHash, :Svg, :Utilities, :Variants
end
