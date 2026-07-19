# テスト・互換性設計

## 互換性の基準

移植基準は `boringdesigners/boring-avatars` のfull SHA [`d0ff2582a8921b643a89de4a4912be28938a828b`](https://github.com/boringdesigners/boring-avatars/tree/d0ff2582a8921b643a89de4a4912be28938a828b) とする。このcommitの `package.json` は2.0.4だが、GitHub latest releaseはv2.0.2である。fixture、設計書、third-party noticeにはshort SHAや可変の `master` URLではなくfull SHAを記録する。

テスト対象のCore APIは [Core ライブラリ設計](core-library.md)、Rails固有のload/safety契約は [Rails binding 設計](rails-binding.md)、実装順は [アーキテクチャ](architecture.md) を参照する。

## 「描画互換」の定義

有効な入力について、次を移植元と一致させる。

- UTF-16 code unitとsigned 32-bit overflowによるname hash
- paletteから色を選ぶindexと順序
- variantごとの固定path、要素数、要素順
- 座標、サイズ、角丸、回転、移動、scale
- Beamの顔色contrast、目、口、wrapper形状
- Marbleのblur filterとoverlay blend
- Pixelのrect配置と描画順
- Sunsetのgradient方向
- Ringのlayer構成
- 共通maskによるround/square形状

比較対象外は次のとおり。

- React component APIとReact propsの型
- React `useId` が生成する文字列
- attribute順、self-closing表記などReactとRuby serializerの字句差
- whitespaceだけの差
- byte-for-byteのSVG文字列

互換性テストは視覚的な印象だけで判断せず、正規化したSVG DOMの構造と属性値で判定する。

## 意図的な非互換

| 移植元 | Ruby版 |
|---|---|
| name省略時は `Clara Barton` | nameは必須。空文字は許可 |
| 未知variantは `marble` | `ArgumentError` |
| `geometric` / `abstract` alias | 非対応、`ArgumentError` |
| 空paletteや無効色の挙動は未定義 | 1色以上の `#RRGGBB` を必須化 |
| 任意のReact SVG propsで固定属性も上書き可能 | 安全なroot属性allowlistだけ許可 |
| mask/filter IDはReact tree依存 | Coreは入力digest、Railsはrandom prefix |
| Sunset gradient IDは空白除去name | 安全なprefix由来ID |
| Reactがmarkupをescape | CoreのXML serializerが一元的にescape |

これらを後方互換目的でalias、fallback、警告付き受理へ変更しない。移植元の更新を取り込む場合も、Ruby版の公開契約変更として個別に判断する。

## テスト基盤

- test frameworkはMinitestとする。
- `rake test` をローカルとCIの共通entrypointにする。
- `rake typecheck` で配布対象のRBSとSorbet RBIを検証する。RBSは `rbs -I sig validate` とSteepの公開API契約fixture、SorbetはRBIと `# typed: strong` の公開API契約fixtureを入力にする。実装本体へのSorbet導入とは分離する。
- 公開API manifestは実装から取得したpublic method集合と完全一致させ、Sorbet/RBS双方の契約fixtureが全項目を使用することを検査する。Sorbet fixtureの `untyped_usages` はゼロを必須とし、公開API型カバレッジ100%をCIの失敗条件にする。
- SVG parsingとcanonical比較にはdevelopment/test dependencyとしてNokogiriを使用し、runtime dependencyには追加しない。
- processごとのload状態を検証するテストは `Open3.capture3` などで新しいRuby processを起動する。
- Rails系列は `BUNDLE_GEMFILE` で切り替える明示的なmatrix Gemfileを使用し、Appraisalによる生成物を必須にしない。

テストは内部private methodへ過度に依存せず、公開出力、pinned fixture、load stateを中心にする。ただしJavaScript互換hashはアルゴリズムの破壊を早く特定できるよう、独立したunit testも持つ。

## Upstream fixture

移植元にはunit testや公式snapshotがないため、pinned commitからReact server-side renderingでfixtureを生成する。

### 生成手順

1. pinned SHAを一時directoryへcheckoutする。
2. lockfileどおり `npm ci` とbuildを行う。
3. `react-dom/server` の `renderToStaticMarkup` で公開 `Avatar` componentを描画する。
4. 入力optionとraw SVGをJSON Lines fixtureへ保存する。
5. fixture metadataへupstream repository、full SHA、Node/npm version、生成commandを記録する。

fixture更新scriptはnetworkやupstreamのdefault branchを暗黙参照せず、記録されたSHAを必須引数にする。通常のRuby test実行時はNodeやnetworkを必要とせず、commit済みfixtureだけを読む。

実装済みの更新commandは `script/update_upstream_fixtures PATH_TO_PINNED_CHECKOUT` とする。指定checkoutのHEADが上記full SHAと一致しない場合は、fixtureを書き換える前に失敗する。

### DOM正規化

ReactとRubyで異なる内部IDを比較可能にするため、双方をXMLとしてparseし、次の正規化を行う。

1. document順に各 `id` を `internal-1`、`internal-2` のようなtokenへmapする。
2. `mask`、`filter`、`fill` などの `url(#id)` fragment参照も同じmapで置換する。
3. attribute順とempty-element表記をXML canonicalizationで統一する。
4. style宣言はproperty/valueを保ったまま、serializer由来の空白だけを正規化する。
5. ID以外の値、要素順、path data、transform、色は変更しない。

参照先のないfragment、重複して異なる定義を持つID、SVG外を参照するURLがあれば、正規化前にテストを失敗させる。

## Fixtureケース

upstream parity fixtureは17ケース × 全6 variantの102件をtable-driven testとして持つ。fixtureケース定義は `test/support/upstream_fixture_cases.rb` を生成scriptと比較testで共有し、ケース定義・生成結果・比較入力の乖離を防ぐ。raw SVGは `fixtures.jsonl` の1行1件として保存し、metadataにはケース定義と件数を記録する。

最低限、次を固定fixtureまたはtable-driven testとして持つ。

### 描画

- 全6 variant × default palette × `Maria Mitchell`
- 全6 variantの `square: true`
- 全6 variantの `title: true`
- palette長1、2、5
- 整数・小数の数値sizeとstring size
- ASCIIの似た名前と長い名前
- 空文字、日本語、emoji、合成文字、分解文字
- XML escapeが必要な文字を含むtitle

### Unicode/hash

- 空文字
- `Clara Barton`
- `日本語`
- `😀`
- 合成文字 `é`
- 分解文字 `e\u0301`

期待hashはCore設計に記載したvectorと一致させる。emojiはUTF-16 surrogate pairとして処理されることを個別に確認する。

### Validationとsecurity

- `nil` やString以外のname
- invalid encodingとXML 1.0で禁止されるcontrol character
- 空palette、String以外のpalette、無効hex、空要素
- 未知variant、case違い、`geometric`、`abstract`
- `nil`、0、負数、NaN、Infinity、不正grammarのsize
- boolean以外のsquare/title
- 不正または長すぎるID prefix
- allowlist外属性、正規化後の重複属性、非scalar値
- tagやquoteを含むname、class、data、aria値
- `style`、`href`、`xlink:href`、`onload`、固定構造属性の拒否

悪意ある値のテストは単に文字列に `<script>` がないことを見るだけでなく、XML parse後に想定外の要素・属性が増えていないことを確認する。

## 内部IDテスト

Coreについて次を確認する。

- 同じ全入力から同じprefixとSVGが生成される。
- name、variant、palette、squareのいずれかが変わればprefixが変わる。
- size、title、追加root属性だけを変えてもdefs用prefixは変わらない。
- 全 `url(#...)` が同じSVG内の一意なIDへ解決する。
- Sunsetで同じname・異なるpaletteを並べてもgradientが混線しない。

Rails helperについて次を確認する。

- `SecureRandom` をstubしたテストでは指定prefixの安定したSVGを得られる。
- 通常の2回の呼び出しでは内部ID集合が互いに素になる。
- 明示的な `id_prefix` はCoreと同じvalidationを受ける。

## Require境界テスト

各シナリオを新しいRuby processで実行する。

1. `require "boring_avatars"` のみでActiveSupport/ActionViewがロードされず、helperが存在しない。
2. ActionViewを先にロードしてからCoreだけをrequireしてもhelperが追加されない。
3. bindingをrequireしてからActionViewをロードするとhelperが追加される。
4. ActionViewをロードしてからbindingをrequireしてもhelperが追加される。
5. bindingを複数回requireしてもmodule ancestorや動作が重複しない。
6. Rails系gemを利用できない環境でbinding requireが `LoadError` になる。
7. helperの戻り値が `ActiveSupport::SafeBuffer` かつ `html_safe? == true` になる。
8. Core validation errorがhelperから変更されず伝播する。

`$LOADED_FEATURES`、ActionViewのancestors、helper呼び出し結果を組み合わせ、定数が偶然定義されているだけの状態を成功とみなさない。

## 対応matrix

初版の `required_ruby_version` は `>= 3.3` とする。Core CIは次のRuby系列の最新patchを対象にする。

- Ruby 3.3
- Ruby 3.4
- Ruby 4.0

Rails bindingはActionView 8.0と8.1の最新patchをmatrix Gemfileで固定し、上記Ruby系列との全組み合わせをCI対象にする。dependency resolution不能な組み合わせを黙ってallow-failureにせず、対応範囲または依存選択の誤りとして解決する。

Rails 7以前と未検証の将来Rails majorはサポート対象に含めない。RailsがoptionalであるためgemspecにはRails version constraintを置かず、文書とCI結果を保証範囲の根拠とする。

## Gem package検証

built gemに対して次を検証する。

- CoreとRails bindingの必要ファイルが含まれる。
- test、fixture、一時生成物、upstream checkoutを不要に同梱しない。
- Rails、ActionView、ActiveSupportのruntime dependencyがない。
- `required_ruby_version >= 3.3` が設定されている。
- gem metadataのlicenseがMITである。
- projectのLICENSEとupstream noticeが含まれる。

## ライセンス

移植元はMIT Licenseで、`Copyright (c) 2021 boringdesigners` の表示を持つ。Ruby版もMITとし、将来の実装・配布時には次を満たす。

- project自身の `LICENSE` を置く。
- upstreamのcopyrightとMIT license本文を `THIRD_PARTY_NOTICES.md` などへ実体として収録する。
- gemspecの `license` / `licenses` とpackage対象へ反映する。
- built gemにLICENSEとnoticeが含まれることを自動テストする。

単にupstream URLだけを記載してlicense本文を省略してはならない。

## 完成条件

- pinned fixtureとの正規化DOM比較が全6 variantで成功する。
- hash vector、validation、security、ID参照の全テストが成功する。
- Core-only requireとRails opt-in requireの境界が別processテストで保証される。
- Ruby 3.3・3.4・4.0およびRails 8.0・8.1 matrixが成功する。
- built gemの依存・同梱物・license検査が成功する。
- built gemに `sig/boring_avatars.rbs` と `rbi/boring_avatars.rbi` が同梱され、両方の型検証が成功する。
- 4つの設計文書でAPI、default、対応範囲、意図的非互換が一致している。
