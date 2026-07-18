# frozen_string_literal: true

class BoringAvatarsRbsContract
  include BoringAvatars::Bindings::Rails::ViewHelper

  # covers: BoringAvatars.generate
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
