# frozen_string_literal: true

require_relative "test_helper"

class NameHashTest < Minitest::Test
  CASES = {
    "Clara Barton" => 645_088_871,
    "" => 0,
    "日本語" => 25_921_943,
    "😀" => 1_772_899,
    "e\u0301" => 3900,
    "é" => 233
  }.freeze

  def test_matches_javascript_utf16_hash_vectors
    name_hash = BoringAvatars.const_get(:NameHash)

    CASES.each do |name, expected|
      assert_equal expected, name_hash.call(name), name
    end
  end
end

