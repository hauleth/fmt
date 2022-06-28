# Fmt

Formatting sigil for Elixir. Inspired by Rust `format!` macro and Python's
`f-strings`

```elixir
import Fmt
foo = 1
~F"#{foo :: x}" == "0x1"
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `sigil_f` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fmt, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/sigil_f](https://hexdocs.pm/sigil_f).

