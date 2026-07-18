# frozen_string_literal: true

require_relative "test_helper"

class RailsBindingTest < Minitest::Test
  def setup
    require "action_view"
    require "boring_avatars/bindings/rails"
  rescue LoadError
    skip "ActionView is only installed in the Rails matrix"
  end

  def test_helper_returns_safe_buffer
    view = Class.new do
      include BoringAvatars::Bindings::Rails::ViewHelper
    end.new

      result = view.boring_avatar(
      "Maria & Mitchell",
      variant: :beam,
      id_prefix: "ba-0123456789abcdef0123",
      class: ["avatar", "profile-avatar"],
      aria: { label: "Maria & Mitchell" },
        data: { controller: "avatar", "user_id" => 42 },
        lang: nil
    )

    assert_instance_of ActiveSupport::SafeBuffer, result
    assert_predicate result, :html_safe?
    document = parse_svg(result)
    assert_equal "avatar profile-avatar", document.root["class"]
    assert_equal "Maria & Mitchell", document.root["aria-label"]
    assert_equal "avatar", document.root["data-controller"]
    assert_equal "42", document.root["data-user-id"]
    assert_equal "ba-0123456789abcdef0123-mask", internal_ids(document).first
  end

  def test_two_calls_receive_disjoint_internal_ids
    view = Class.new do
      include BoringAvatars::Bindings::Rails::ViewHelper
    end.new
    documents = [view.boring_avatar("name", variant: :sunset), view.boring_avatar("name", variant: :sunset)].map do |svg|
      parse_svg(svg)
    end

    assert_empty internal_ids(documents[0]) & internal_ids(documents[1])
  end

  def test_explicit_prefix_is_stable
    view = Class.new do
      include BoringAvatars::Bindings::Rails::ViewHelper
    end.new

    first = view.boring_avatar("name", id_prefix: "stable-avatar")
    second = view.boring_avatar("name", id_prefix: "stable-avatar")
    assert_equal first, second
  end

  def test_nested_attribute_collisions_raise
    view = Class.new do
      include BoringAvatars::Bindings::Rails::ViewHelper
    end.new

    assert_raises(ArgumentError) do
      view.boring_avatar("name", aria: { label: "first" }, :"aria-label" => "second")
    end
  end

  def test_action_view_load_order_in_fresh_processes
    lib = File.expand_path("../lib", __dir__)
    scripts = [
      <<~RUBY,
        require "boring_avatars/bindings/rails"
        require "action_view"
        abort unless ActionView::Base.method_defined?(:boring_avatar)
      RUBY
      <<~RUBY
        require "action_view"
        require "boring_avatars/bindings/rails"
        abort unless ActionView::Base.method_defined?(:boring_avatar)
      RUBY
    ]

    scripts.each do |script|
      _output, error, status = Open3.capture3(RbConfig.ruby, "-I#{lib}", "-e", script)
      assert status.success?, error
    end
  end
end
