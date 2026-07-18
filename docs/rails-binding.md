# Rails binding 設計

## 目的

Rails bindingは、Rails ViewからCoreのSVG生成を呼び出し、escape済みの結果を `ActiveSupport::SafeBuffer` として返す薄いadapterである。描画アルゴリズム、default値、validationをRails側に複製しない。

Coreの契約は [Core ライブラリ設計](core-library.md)、全体構成は [アーキテクチャ](architecture.md)、ロード境界を含むテストは [テスト・互換性設計](testing-and-compatibility.md) を参照する。

## opt-inロード

次の2つのrequire pathは明確に異なる契約を持つ。

```ruby
require "boring_avatars"
```

- Coreだけをロードする。
- ActiveSupport、ActionView、Rails bindingをロードしない。
- Railsが既にロード済みでもhelperを登録しない。

```ruby
require "boring_avatars/bindings/rails"
```

- Coreをロードする。
- `active_support/lazy_load_hooks` と `active_support/core_ext/string/output_safety` をロードする。
- View Helperを定義し、ActionViewのlazy-load hookへ登録する。
- ActionView自体をeager loadしない。

Rails利用者はGemfileで自動require先を指定できる。

```ruby
gem "boring_avatars", require: "boring_avatars/bindings/rails"
```

または、GemfileではCoreだけを読み込み、initializerなどでbindingを明示的にrequireする。

## Helper登録

RailtieやEngineは作らず、entrypointで直接load hookを登録する。

```ruby
require "boring_avatars"
require "active_support/lazy_load_hooks"
require "active_support/core_ext/string/output_safety"
require "boring_avatars/bindings/rails/view_helper"

ActiveSupport.on_load(:action_view) do
  include ::BoringAvatars::Bindings::Rails::ViewHelper
end
```

`ActiveSupport.on_load` はActionViewが既にload hookを実行済みなら登録時に即時適用し、未ロードなら後の `run_load_hooks(:action_view, self)` で適用する。このため、次の両方を同じ契約として保証する。

1. bindingをrequireした後にActionViewをロードする。
2. ActionViewをロードした後にbindingをrequireする。

gemのコードはRailsのapplication autoload pathやreload対象に置かない。`to_prepare`、initializer、Zeitwerk向け登録は不要とする。Rubyの `require` と同じく複数回のrequireは冪等でなければならない。

## 依存関係

`boring_avatars.gemspec` に `rails`、`railties`、`actionview`、`activesupport` のruntime dependencyを追加しない。RubyGemsにはoptional runtime dependencyの表現がないため、追加するとCoreだけの利用者にもRails系gemのinstallを強制してしまう。

Rails bindingを利用するapplicationがRails／ActiveSupportを提供する。提供されていない環境でbindingをrequireした場合、`LoadError` をrescueせず伝播させる。警告だけでhelperを無効化する処理や、Coreへfallbackする処理は実装しない。

開発・CIではRails系列ごとのGemfileからActionViewをdevelopment/test dependencyとして与える。

## View Helper API

公開helperは `boring_avatar` だけとする。

```ruby
boring_avatar(
  name,
  variant: :marble,
  colors: ["#92A1C6", "#146A7C", "#F0AB3D", "#C271B4", "#C20D90"],
  size: "40px",
  square: false,
  title: false,
  id_prefix: nil,
  **svg_attributes
) # => ActiveSupport::SafeBuffer
```

- semantic optionの意味とvalidationはCoreと同じである。
- Rails独自defaultは持たない。
- Coreの `attributes:` 引数はhelperでは公開せず、残りのkeywordをroot SVG属性として扱う。
- 未知keywordは属性allowlistで検証され、許可されていなければ `ArgumentError` になる。
- Coreが送出した例外はそのまま呼び出し元へ伝える。

### 使用例

```erb
<%= boring_avatar(
  current_user.email,
  variant: :bauhaus,
  size: "3rem",
  class: ["avatar", "avatar--navigation"],
  aria: { label: "#{current_user.name}のavatar" },
  data: { controller: "avatar", user_id: current_user.id }
) %>
```

`name`、palette、属性値にuser inputが含まれていても、値はCore serializerでescapeされる。呼び出し側で `raw` や `html_safe` を付ける必要はない。

## Rails形式属性の正規化

helperはCoreのflat属性allowlistに合わせ、次のRails向けshorthandだけを正規化する。

- `class:` はString、またはStringだけを含むArrayを許可する。Arrayは空要素を除外せず、空文字があれば `ArgumentError` とし、半角spaceで結合する。
- `data:` はHashを受け、keyの `_` を `-` に変換して `data-<key>` へ展開する。
- `aria:` はHashを受け、keyの `_` を `-` に変換して `aria-<key>` へ展開する。
- `id`、`lang`、`tabindex`、`focusable` はCoreと同じscalar値を受ける。
- `nil` は属性を省略し、booleanは文字列 `true` / `false` として渡す。

`data:` / `aria:` のnested Hash、ArrayやHashの自動JSON化、`class` 以外のArray展開は初版では扱わない。正規化後に同じ属性名が複数回現れた場合は、後勝ちにせず `ArgumentError` とする。

属性値が `ActiveSupport::SafeBuffer` であってもsafeという印を信頼せず、Coreでは通常のStringとして再度XML escapeする。

## 内部IDの一意性

Reactの `useId` に相当する一意性をRails View内で得るため、helperは `id_prefix: nil` の各呼び出しで次のprefixを生成する。

```ruby
"ba-#{SecureRandom.hex(10)}"
```

生成したprefixをCoreの `id_prefix:` へ渡し、完成後のSVGを文字列置換しない。20桁hexの衝突確率は実用上無視でき、partial、fragment cache、Turboで別render結果が同じdocumentへ追加される場合にもview-local counterより安全である。

呼び出し側が有効な `id_prefix` を明示した場合はそれをそのままCoreへ渡す。snapshotや固定HTMLを必要とする場合は、テストやapplication側で明示prefixを使える。

## HTML safety

`html_safe` はescape処理ではなく、「これ以上escapeしなくてよい」という信頼宣言である。次の順序を変更しない。

1. helperがRails形式属性を通常のRuby値へ正規化する。
2. Coreが全入力を検証し、element treeを作る。
3. Core serializerがtitle textとすべての属性値をXML escapeする。
4. Coreが完成済みの通常のStringを返す。
5. helperが最後に一度だけSafeBuffer化する。

SafeBuffer化後にname、属性、ID、wrapper markupを連結してはならない。生成済み `<svg>` 開始tagを正規表現で差し替える方法や、Railsの `tag.attributes` が返すmarkupをraw挿入する方法も採用しない。

## Loadと安全性の受け入れ条件

- Core require後の `$LOADED_FEATURES` にActiveSupport、ActionView、Rails bindingがない。
- Railsが先にロードされてもCore requireだけでは `boring_avatar` が追加されない。
- bindingとActionViewのどちらを先にロードしても最終的にhelperが利用できる。
- helperの戻り値が `ActiveSupport::SafeBuffer` かつ `html_safe?` である。
- Core出力とhelper出力は、helperが付与する内部ID以外のDOM構造が一致する。
- 同じViewで2回呼んだ結果の内部ID集合が交差せず、すべてのfragment参照が各SVG内で解決する。
- Railsが存在しない場合にbinding requireが黙って成功しない。
