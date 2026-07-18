# frozen_string_literal: true

require "json"

ROOT = File.expand_path("..", __dir__)
require File.join(ROOT, "lib/boring_avatars")
require File.join(ROOT, "lib/boring_avatars/bindings/rails/view_helper")

MANIFEST = File.join(ROOT, "test/type_contracts/public_api.txt")
CONTRACTS = %w[sorbet_contract.rb rbs_contract.rb].map do |name|
  File.join(ROOT, "test/type_contracts", name)
end.freeze
FILE_TABLE = File.join(ROOT, "tmp/sorbet-file-table.json")

expected = File.readlines(MANIFEST, chomp: true).reject(&:empty?).sort

raise "public API manifest must not be empty" if expected.empty?

actual = [
  *BoringAvatars.singleton_class.public_instance_methods(false).map { |name| "BoringAvatars.#{name}" },
  *BoringAvatars::Bindings::Rails::ViewHelper.public_instance_methods(false).map do |name|
    "BoringAvatars::Bindings::Rails::ViewHelper##{name}"
  end
].sort

unless actual == expected
  missing = actual - expected
  stale = expected - actual
  raise "public API manifest mismatch (missing=#{missing.inspect}, stale=#{stale.inspect})"
end

CONTRACTS.each do |path|
  covered = File.readlines(path, chomp: true).filter_map do |line|
    line[/^\s*# covers: (.+)$/, 1]
  end.sort

  next if covered == expected

  missing = expected - covered
  unexpected = covered - expected
  raise "#{path}: coverage mismatch (missing=#{missing.inspect}, unexpected=#{unexpected.inspect})"
end

files = JSON.parse(File.read(FILE_TABLE)).fetch("files")
contract_path = File.join(ROOT, "test/type_contracts/sorbet_contract.rb")
row = files.find { |entry| File.expand_path(entry.fetch("path"), ROOT) == contract_path }
raise "Sorbet coverage output does not include #{contract_path}" unless row
raise "Sorbet contract must use # typed: strong" unless row.fetch("sigil") == "Strong"

untyped_usages = row.fetch("untyped_usages", 0)
raise "Sorbet contract contains #{untyped_usages} untyped usages" unless untyped_usages.zero?

puts "Public API type coverage: 100% (#{expected.length}/#{expected.length}, Sorbet and RBS)"
