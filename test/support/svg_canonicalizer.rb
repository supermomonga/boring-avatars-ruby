# frozen_string_literal: true

require "nokogiri"

module SvgCanonicalizer
  module_function

  def call(svg)
    document = Nokogiri::XML(svg) { |config| config.strict.nonet }
    id_map = document.xpath("//*[@id]").each_with_index.to_h do |node, index|
      [node["id"], "internal-#{index + 1}"]
    end

    document.xpath("//*[@id]").each { |node| node["id"] = id_map.fetch(node["id"]) }
    document.xpath("//*[@*]").each do |node|
      node.attribute_nodes.each do |attribute|
        attribute.value = attribute.value.gsub(/url\(#([^)]+)\)/) do
          original = Regexp.last_match(1)
          "url(##{id_map.fetch(original, original)})"
        end
      end
    end

    document.canonicalize
  end
end

