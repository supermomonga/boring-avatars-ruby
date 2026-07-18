# frozen_string_literal: true

require "boring_avatars"
require "active_support/lazy_load_hooks"
require "active_support/core_ext/string/output_safety"
require "boring_avatars/bindings/rails/view_helper"

ActiveSupport.on_load(:action_view) do
  include ::BoringAvatars::Bindings::Rails::ViewHelper
end

