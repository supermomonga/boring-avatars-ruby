# typed: strong
# frozen_string_literal: true

class BoringAvatarsSorbetContract
  extend T::Sig
  include BoringAvatars::Bindings::Rails::ViewHelper

  # covers: BoringAvatars.generate
  sig { returns(String) }
  def core_avatar
    BoringAvatars.generate(
      "Ada Lovelace",
      variant: :beam,
      colors: ["#264653", "#2A9D8F"],
      size: 64,
      square: false,
      title: true,
      id_prefix: "avatar",
      attributes: { class: "avatar" }
    )
  end

  # covers: BoringAvatars::Bindings::Rails::ViewHelper#boring_avatar
  sig { returns(String) }
  def rails_avatar
    boring_avatar(
      "Ada Lovelace",
      variant: "bauhaus",
      colors: ["#264653", "#2A9D8F"],
      size: "4rem",
      square: true,
      title: false,
      id_prefix: "avatar",
      class: ["avatar", "avatar--large"],
      aria: { label: "Ada Lovelace" }
    )
  end
end
