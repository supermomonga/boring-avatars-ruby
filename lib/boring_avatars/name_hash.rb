# frozen_string_literal: true

module BoringAvatars
  module NameHash
    UINT32_MASK = 0xFFFF_FFFF
    INT32_SIGN = 0x8000_0000
    UINT32_SIZE = 0x1_0000_0000

    module_function

    def call(name)
      name.encode(Encoding::UTF_16LE).unpack("v*").reduce(0) do |hash, code_unit|
        value = ((hash * 31) + code_unit) & UINT32_MASK
        value >= INT32_SIGN ? value - UINT32_SIZE : value
      end.abs
    end
  end
end

