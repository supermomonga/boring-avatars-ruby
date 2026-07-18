# Boring Avatars Ruby アーキテクチャ

## この文書について

この文書は、Boring Avatars の Ruby 実装である `boring_avatars` gem の全体設計と実装順序を定義する。描画アルゴリズムの詳細は [Core ライブラリ設計](core-library.md)、Rails 固有部分は [Rails binding 設計](rails-binding.md)、互換性と検証方法は [テスト・互換性設計](testing-and-compatibility.md) を参照する。

移植元は `boringdesigners/boring-avatars` の commit [`d0ff2582a8921b643a89de4a4912be28938a828b`](https://github.com/boringdesigners/boring-avatars/tree/d0ff2582a8921b643a89de4a4912be28938a828b) に固定する。移植元の `package.json` は 2.0.4 だが、GitHub 上の最新リリースは v2.0.2 であるため、バージョン番号ではなく full SHA を互換性の基準とする。

## 目的

- 名前とカラーパレットから、外部サービスを使わず決定的に SVG avatar を生成する。
- React 版の6 variantについて、ハッシュ、色選択、図形、transformの描画結果を移植する。
- Rails 非依存のCoreと、明示的に読み込むRails View Helperを単一gemで提供する。
- Core利用時にはRails、ActiveSupport、ActionViewをインストール・ロードさせない。
- 入力検証と一元化したXML serializerにより、生成結果をinline SVGとして安全に扱えるようにする。

## 対象外

- PNGなどSVG以外の画像生成
- Boring AvatarsのWeb API、Web UI、React component
- 設定DSL、global configuration、plugin API
- Rails 7以前の互換shim
- `geometric`、`abstract` など移植元のdeprecated alias
- Reactのcomponent treeに依存する `useId` や、SVG文字列のbyte-for-byte互換
- 移植元の未知variantから `marble` への暗黙fallback

## 公開インターフェース

gem名は `boring_avatars`、トップレベルnamespaceは `BoringAvatars` とする。Coreの公開メソッドは `BoringAvatars.generate` のみとし、variant rendererやhash utilityは実装詳細とする。

```ruby
require "boring_avatars"

svg = BoringAvatars.generate(
  "Maria Mitchell",
  variant: :beam,
  colors: ["#264653", "#2A9D8F", "#E9C46A", "#F4A261", "#E76F51"],
  size: "64px",
  square: false,
  title: true,
  id_prefix: nil,
  attributes: {
    class: "avatar",
    :"aria-label" => "Maria Mitchell"
  }
)
```

戻り値はUTF-8の通常の `String` であり、Coreは `ActiveSupport::SafeBuffer` や `html_safe` を認識しない。

Railsでは次のentrypointとhelperだけを公開契約とする。

```ruby
require "boring_avatars/bindings/rails"

boring_avatar(
  "Maria Mitchell",
  variant: :beam,
  size: 64,
  class: "avatar",
  aria: { label: "Maria Mitchell" },
  data: { controller: "profile-avatar" }
)
```

`boring_avatar` はCoreと同じSVGを `ActiveSupport::SafeBuffer` として返す。helper moduleの定数名は公開契約に含めない。

## コンポーネント境界

```text
application
  |
  +-- require "boring_avatars"
  |       |
  |       +-- input validation
  |       +-- JavaScript-compatible name hash
  |       +-- variant renderer
  |       +-- SVG node builder / serializer
  |
  +-- require "boring_avatars/bindings/rails"   # opt-in only
          |
          +-- requires Core
          +-- ActiveSupport.on_load(:action_view)
          +-- View Helper
                 |
                 +-- Rails-style attributes normalization
                 +-- random internal ID prefix
                 +-- delegates all rendering to Core
                 +-- final SafeBuffer conversion
```

依存方向は常にRails bindingからCoreへの一方向とする。Coreからbindingを探索する処理、`defined?(Rails)` による自動検出、Railsがない場合のfallbackは実装しない。

## 想定する内部構成

```text
lib/
  boring_avatars.rb
  boring_avatars/
    version.rb
    input.rb
    name_hash.rb
    renderer.rb
    svg/
      element.rb
      serializer.rb
    variants/
      marble.rb
      beam.rb
      pixel.rb
      sunset.rb
      ring.rb
      bauhaus.rb
    bindings/
      rails.rb
      rails/
        view_helper.rb
```

- `boring_avatars.rb` はCoreの公開facadeと必要なCoreファイルだけを読み込む。
- `Input` は型、値域、palette、追加属性を検証し、rendererが扱う正規化済みの不変データを作る。
- `NameHash` はJavaScript互換hashだけを担当する。
- `Renderer` は共通の `<svg>`、`<title>`、mask、IDを組み立て、選択したvariantへ内部要素の生成を委譲する。
- variantはSVG文字列を連結せず、serializer用のelement treeを返す。
- `Svg::Serializer` だけがXML文字列を生成する。variantやRails helperで手作業のescapeや文字列差し込みを行わない。
- `bindings/rails.rb` はCoreと必要最小限のActiveSupport機能を明示的にrequireし、load hookを登録する。

内部定数は公開APIとして文書化せず、可能なものは `private_constant` とする。将来のrefactorで内部ファイル構成を変更しても、公開メソッドとrequire pathは維持できる構造にする。

## 生成データフロー

1. `BoringAvatars.generate` が引数を受け取る。
2. `Input` がnameをUTF-8へtranscodeし、variant、palette、size、boolean、ID prefix、追加属性を検証する。
3. `NameHash` がUTF-16 code unit列からsigned 32-bit hashを計算する。
4. ID prefixが省略された場合、正規化済みのvariant、name、palette、squareから決定的なprefixを作る。
5. variant rendererがhashとpaletteから色・座標・transformを計算し、SVG element treeを返す。
6. 共通rendererがtitle、mask、defs、ルート属性を統合する。
7. serializerがtext nodeと属性値をescapeし、UTF-8のSVG `String` を返す。
8. Rails helperの場合に限り、完成済みの文字列を最後に一度だけSafeBufferへ変換する。

すべての計算は呼び出しごとのローカルデータで完結させる。Coreに連番、乱数、mutableなglobal configurationを持たせず、同じ入力から同じ文字列を生成する。

## エラー方針

- 公開引数の型・値・文字encoding・属性が契約に違反した場合は `ArgumentError` を送出する。
- 未知variantを別variantへ置き換えない。
- 不正な追加属性を削除・修正せず、呼び出し全体を失敗させる。
- Rails helperはCoreの例外をrescueしてfallback SVGへ置き換えない。
- Rails bindingをRails/ActiveSupportのない環境でrequireした場合は、依存元の通常の `LoadError` を伝播させる。

独自の例外classは初版では公開しない。利用者が修正すべき入力エラーと、依存が存在しないロードエラーをRuby標準の例外で区別する。

## 実装順序

1. gem metadataとCore entrypointを作り、Core-only requireがRailsをロードしないことを先に固定する。
2. 入力モデル、JavaScript互換hash、決定的ID、XML element/serializerを実装し、security testを通す。
3. 6 variantを1つずつ移植し、各variant追加時にpinned fixtureとの構造比較を通す。
4. Rails View Helperと `ActiveSupport.on_load(:action_view)` を追加し、require順序を別processで検証する。
5. Ruby/Rails matrix、built gem内容、ライセンスnoticeを検証して初版をリリースする。

各段階で一時的なfallbackや未検証variantを公開しない。6 variantとCore/Rails境界の受け入れ条件がすべて満たされた時点を初版完成とする。
