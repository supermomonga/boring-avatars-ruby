# Core ライブラリ設計

## 責務

CoreはRailsに依存せず、正規化済みの入力からBoring Avatars互換のinline SVGを生成する。公開APIは `BoringAvatars.generate` だけとし、次の責務を内部で分離する。

- 入力検証と正規化
- JavaScript互換のname hash
- variant固有パラメーターとSVG要素の生成
- 内部IDの生成と参照整合性
- XML 1.0として安全な直列化

全体の依存関係とRailsとの境界は [アーキテクチャ](architecture.md)、検証方法は [テスト・互換性設計](testing-and-compatibility.md) を参照する。

## 公開API

```ruby
BoringAvatars.generate(
  name,
  variant: :marble,
  colors: ["#92A1C6", "#146A7C", "#F0AB3D", "#C271B4", "#C20D90"],
  size: "40px",
  square: false,
  title: false,
  id_prefix: nil,
  attributes: {}
) # => String
```

### 入力契約

| 引数 | 契約 |
|---|---|
| `name` | 必須の `String`。空文字は許可する。有効な文字encodingからUTF-8へ変換できること。trim、case folding、Unicode normalizationは行わない。XML 1.0で使用できないcontrol characterは拒否する。 |
| `variant` | `Symbol` または `String`。`marble`、`beam`、`pixel`、`sunset`、`ring`、`bauhaus` の完全一致だけを許可する。case変換は行わない。 |
| `colors` | 1要素以上の `Array<String>`。各要素は `\A#[0-9A-Fa-f]{6}\z` に一致すること。順序と文字caseを保持する。 |
| `size` | 0より大きい `Integer`、有限の `Float`、または正の10進数に任意で `px`、`em`、`rem`、`%`、`vw`、`vh`、`vmin`、`vmax` を付けた `String`。符号、指数表現、空白、`calc()` は初版では許可しない。 |
| `square` | `true` または `false` のみ。truthy/falsy変換はしない。 |
| `title` | `true` または `false` のみ。`true` の場合はnameをtext nodeとする `<title>` を追加する。空nameなら空の `<title>` になる。 |
| `id_prefix` | `nil` または `\A[A-Za-z][A-Za-z0-9_-]{0,63}\z` に一致する `String`。`nil` は決定的prefixを生成する。 |
| `attributes` | flatな `Hash`。許可する名前と値型は後述する。 |

String形式のsizeは次のgrammarに固定する。

```text
(digits ["." digits] | "." digits) [unit]
unit = "px" | "em" | "rem" | "%" | "vw" | "vh" | "vmin" | "vmax"
numeric value > 0
```

入力違反はすべて `ArgumentError` とする。配列や文字列を暗黙に変換せず、入力Hashや配列を破壊的に変更しない。

## JavaScript互換hash

移植元の [`src/lib/utilities.ts`](https://github.com/boringdesigners/boring-avatars/blob/d0ff2582a8921b643a89de4a4912be28938a828b/src/lib/utilities.ts) と同じ結果を得るため、Rubyの `String#bytes` や `String#codepoints` は使用しない。UTF-8へ変換済みのnameをUTF-16LEへencodeし、16-bit unsigned integer列として処理する。

```text
hash = 0

for each UTF-16 code unit:
  hash = 31 * hash + code_unit
  hash = signed_int32(hash)

result = abs(hash)
```

`signed_int32` は各反復で下位32 bitを残し、最上位bitが立っている場合は `2^32` を引く。最後の値が `-2^31` の場合、JavaScriptの `Math.abs` と同様に `2^31` を返す。

基準vectorは次のとおり。

| name | hash |
|---|---:|
| `Clara Barton` | 645088871 |
| 空文字 | 0 |
| `日本語` | 25921943 |
| `😀` | 1772899 |
| `e\u0301` | 3900 |
| `é` | 233 |

合成文字と分解文字は異なる入力であり、同じhashへ正規化しない。

### 共通utility

variantの式では次の意味を使用する。

```text
digit(number, n) = floor(number / 10^n) % 10
boolean(number, n) = digit(number, n) が偶数
unit(number, range, n = nil):
  value = number % range
  n が指定され、digit(number, n) が偶数なら -value、それ以外は value
random_color(number, colors) = colors[number % colors.length]
```

Beamのcontrast色は `#` を除いた6桁をRGBとして読み、次のYIQが128以上なら `#000000`、未満なら `#FFFFFF` とする。

```text
yiq = (r * 299 + g * 587 + b * 114) / 1000
```

paletteを `#RRGGBB` に限定するため、移植元の無効CSS色に対する未定義挙動は持ち込まない。

## 内部ID

mask、filter、gradientのIDはnameを直接埋め込まない。Coreの `id_prefix: nil` は次のcanonical byte sequenceから決定的に生成する。

```text
parts = ["v1", variant.to_s, square ? "1" : "0", utf8_name, colors.length.to_s, *colors]
canonical = parts.map { |part| decimal_byte_length(part) + ":" + part }.join
id_prefix = "ba-" + sha256(canonical).hex[0, 20]
```

長さはUTF-8のbyte数で計算する。paletteとsquareを含めることで、同じnameでも異なる定義を持つSVG同士の衝突を避ける。size、title、root attributesは内部defsを変えないためdigest対象に含めない。

内部要素はprefixに固定suffixを付ける。

- mask: `<prefix>-mask`
- Marble filter: `<prefix>-filter`
- Sunset gradient: `<prefix>-gradient-0`、`<prefix>-gradient-1`

すべての `url(#...)` は同じelement tree内に存在するIDだけを参照する。明示された `id_prefix` も同じsuffix規則を使う。

Coreでは同じ入力から同じIDとSVG文字列を得る。同じSVGを1つのHTML文書へ複数埋め込む場合、定義自体は同一なので描画は混線しないが、厳密にIDを一意にしたい呼び出し側は異なる `id_prefix` を渡す。Rails helperはこの処理を自動化する。

## 共通SVG構造

すべてのvariantでルート要素は次の固定属性を持つ。

```xml
<svg
  viewBox="0 0 SIZE SIZE"
  fill="none"
  role="img"
  xmlns="http://www.w3.org/2000/svg"
  width="SIZE_OPTION"
  height="SIZE_OPTION">
</svg>
```

- `SIZE` はvariant内部の座標系であり、`size` optionとは別物である。
- `marble`、`pixel`、`sunset`、`bauhaus` は80、`beam` は36、`ring` は90を使用する。
- `title: true` のとき、ルート直下の最初のchildとして `<title>` を置く。
- 共通maskは `maskUnits="userSpaceOnUse"` と座標・幅・高さをvariantの `SIZE` に合わせる。
- 丸型ではmask内rectの `rx` を `SIZE * 2`、squareでは `rx` 属性自体を省略する。
- root childの順序は、任意のtitle、mask、maskを参照する描画group、必要なdefsの順とする。MarbleとSunsetのdefsも移植元どおり描画groupの後へ置く。
- rootの固定属性は追加属性から上書きできない。

## Variant仕様

variantは移植元のelement順、path data、transform組み立て順を維持する。見た目が近い別実装への置換や、式の簡略化は互換とはみなさない。

### Marble

参照: [`avatar-marble.tsx`](https://github.com/boringdesigners/boring-avatars/blob/d0ff2582a8921b643a89de4a4912be28938a828b/src/lib/components/avatar-marble.tsx)

- `SIZE = 80`、3要素分のpropertiesを作る。
- iを0始まりとして、色は `hash + i`、X/Y移動は `unit(hash * (i + 1), 8, 1|2)`、scaleは `1.2 + unit(hash * (i + 1), 4) / 10`、回転は `unit(hash * (i + 1), 360, 1)`。
- 背景rectの後に固定pathを2枚重ねる。
- 1枚目のpathも移植元どおり `properties[2].scale` を使う。自然に見える `properties[1].scale` へ修正しない。
- 2枚目は `mix-blend-mode: overlay`。
- 両pathは同じfilterを参照し、`feGaussianBlur stdDeviation="7"` を適用する。

### Beam

参照: [`avatar-beam.tsx`](https://github.com/boringdesigners/boring-avatars/blob/d0ff2582a8921b643a89de4a4912be28938a828b/src/lib/components/avatar-beam.tsx)

- `SIZE = 36`。
- wrapper色は `color(hash)`、背景色は `color(hash + 13)`、顔色はwrapper色のYIQ contrast。
- X/Yの事前移動量はそれぞれ `unit(hash, 10, 1|2)`。5未満なら `SIZE / 9` を加える。
- 回転は `unit(hash, 360)`、scaleは `1 + unit(hash, SIZE / 12) / 10`。
- 口の開閉は百の位、wrapperの円/角丸は十の位で決める。
- eye spreadは `unit(hash, 5)`、mouth spreadは `unit(hash, 3)`、顔回転は `unit(hash, 10, 3)`。
- 顔移動の条件式、口の2種類のpath、目の `1.5 x 2` rectを移植元と同じ座標・順序で生成する。

### Pixel

参照: [`avatar-pixel.tsx`](https://github.com/boringdesigners/boring-avatars/blob/d0ff2582a8921b643a89de4a4912be28938a828b/src/lib/components/avatar-pixel.tsx)

- `SIZE = 80`、`10 x 10` のrectを64個生成する。
- i番目の色は `colors[(hash % (i + 1)) % colors.length]`。`hash + i` にはしない。
- maskには `mask-type="alpha"` を付ける。
- 描画順は単純なrow-majorではなく、移植元の順序を維持する。最初の行はX座標 `0, 20, 40, 60, 10, 30, 50, 70`、その後はX座標 `0, 20, 40, 60, 10, 30, 50, 70` ごとにY座標 `10..70` を並べる。

### Sunset

参照: [`avatar-sunset.tsx`](https://github.com/boringdesigners/boring-avatars/blob/d0ff2582a8921b643a89de4a4912be28938a828b/src/lib/components/avatar-sunset.tsx)

- `SIZE = 80`、色は `hash + 0..3` から4色を得る。
- 上半分と下半分を2つの縦方向linear gradientで塗る。
- 上はY座標0から40、下は40から80へ補間する。
- 移植元の空白除去nameによるgradient IDは使用せず、安全なprefixと `-gradient-0|1` を使う。

### Ring

参照: [`avatar-ring.tsx`](https://github.com/boringdesigners/boring-avatars/blob/d0ff2582a8921b643a89de4a4912be28938a828b/src/lib/components/avatar-ring.tsx)

- `SIZE = 90`、`hash + 0..4` から5色を得る。
- 9個のfillは `[c0, c1, c1, c2, c2, c3, c3, c0, c4]` とする。
- 上下背景、半径38・32・26の上下半円、半径23の中央円を移植元のpath dataと順序で重ねる。

### Bauhaus

参照: [`avatar-bauhaus.tsx`](https://github.com/boringdesigners/boring-avatars/blob/d0ff2582a8921b643a89de4a4912be28938a828b/src/lib/components/avatar-bauhaus.tsx)

- `SIZE = 80`、4要素分のpropertiesを作る。
- 色は `hash + i`。
- X/Y移動は `unit(hash * (i + 1), SIZE / 2 - (i + 17), 1|2)`、回転は `unit(hash * (i + 1), 360)`。
- 百の位が偶数ならrectの高さを80、奇数なら10にする。
- 背景rect、移動・回転するrect、移動するcircle、移動・回転するlineの順に描画する。

## 追加root属性

Coreの `attributes:` はflatなHashのみを受け取る。Rails形式のnested `data:` / `aria:` はbinding側でflat化してからCoreへ渡す。

許可する属性名は次だけとする。

- `id`
- `class`
- `lang`
- `tabindex`
- `focusable`
- `aria-` で始まり、後続が小文字英数字と `-` からなる名前
- `data-` で始まり、後続が小文字英数字と `-` からなる名前

Symbol keyは `_` を `-` に変換してから検証し、String keyはそのまま検証する。正規化後に同じ名前となるkeyが複数ある場合は `ArgumentError` とする。

値はString、有限のNumeric、`true`、`false`、`nil` のみを許可する。`nil` は属性を省略し、booleanは `"true"` / `"false"` として出力する。その他のobjectに `to_s` を暗黙適用しない。

許可外の属性は削除せず例外にする。このallowlistにより、`xmlns`、`viewBox`、`width`、`height`、`fill`、`role`、`style`、`href`、`xlink:href`、`on*` はすべて拒否される。

## XML serializer

SVGはテンプレートへの文字列挿入ではなく、内部element treeから直列化する。

- tag名と内部属性名はライブラリ定義の定数だけを使用する。
- text nodeと属性値は、入力が `html_safe?` を返すobjectであっても常に通常値として扱う。
- `&`、`<`、`>`、`"`、`'` をXML用にescapeする。
- XML 1.0で許可されないcode pointを事前に拒否する。
- `nil` の内部属性は省略する。
- 固定root属性を規定順で出力し、追加属性は正規化後の名前でsortして出力する。
- XML declarationは付けず、UTF-8の `<svg>...</svg>` を返す。
- 数値はlocale非依存で出力し、整数値のFloatは不要な `.0` を付けない。負のzeroは `0` とする。

variantやRails helperが生成後のSVGを正規表現で書き換えることは禁止する。ID、属性、titleを含むすべての値はelement treeを組み立てる段階で確定させる。

## Thread safetyと決定性

Coreは入力から出力を得る純粋な処理とし、mutableなmodule state、乱数、時刻、process ID、連番を使用しない。default paletteなどの内部定数はfreezeし、呼び出し元のArray/Stringを破壊しない。

次が同じであれば、Ruby processやthreadにかかわらず同じSVG文字列を返す。

- 正規化後のname
- variant
- paletteとその順序
- size、square、title
- 明示または決定的に生成されたID prefix
- 正規化後の追加属性
