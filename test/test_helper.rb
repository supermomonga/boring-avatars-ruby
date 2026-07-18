# frozen_string_literal: true

require "minitest/autorun"
require "nokogiri"
require "open3"
require "rbconfig"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "boring_avatars"

module SvgTestHelpers
  def parse_svg(svg)
    Nokogiri::XML(svg) { |config| config.strict.nonet }
  end

  def elements(document, name)
    document.xpath("//*[local-name()='#{name}']")
  end

  def internal_ids(document)
    document.xpath("//*[@id]").map { |node| node["id"] }
  end
end

class Minitest::Test
  include SvgTestHelpers
end
