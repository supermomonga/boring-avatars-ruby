# boring_avatars

`boring_avatars` is a Ruby port of [Boring Avatars](https://boringavatars.com/).
It provides a framework-independent SVG generator and an opt-in Rails View
Helper.

## Core

```ruby
require "boring_avatars"

svg = BoringAvatars.generate(
  "Maria Mitchell",
  variant: :beam,
  size: 64,
  colors: ["#264653", "#2A9D8F", "#E9C46A", "#F4A261", "#E76F51"]
)
```

Available variants are `marble`, `beam`, `pixel`, `sunset`, `ring`, and
`bauhaus`.

## Rails

Load the Rails binding explicitly:

```ruby
gem "boring_avatars", require: "boring_avatars/bindings/rails"
```

Then use the helper from a view:

```erb
<%= boring_avatar(
  current_user.email,
  variant: :bauhaus,
  class: "avatar",
  aria: { label: current_user.name }
) %>
```

See [the architecture documentation](docs/architecture.md) for the complete
API and compatibility policy.

## Type signatures

The gem ships both type signature formats:

- Sorbet RBI: `rbi/boring_avatars.rbi`
- RBS: `sig/boring_avatars.rbs`

Run `bundle exec rake typecheck` to validate both definitions. This runs Sorbet
and Steep contract checks and fails unless every public API is covered in both
formats with zero untyped Sorbet usages (100% public API type coverage). Tapioca
can import the RBI exported from the gem's `rbi/` directory, while RBS can load
the installed gem signature by library name.

## License

The gem is available under the MIT License. See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for the upstream Boring
Avatars notice.
