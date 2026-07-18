# frozen_string_literal: true

require "digest"

module BoringAvatars
  module Identifier
    module_function

    def call(input)
      return input.id_prefix if input.id_prefix

      parts = [
        "v1",
        input.variant.to_s,
        input.square ? "1" : "0",
        input.name,
        input.colors.length.to_s,
        *input.colors
      ]
      canonical = parts.map { |part| "#{part.bytesize}:#{part}" }.join
      "ba-#{Digest::SHA256.hexdigest(canonical)[0, 20]}"
    end
  end
end

