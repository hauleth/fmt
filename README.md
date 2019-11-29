# SigilF

Add `sigil_f` for generating formatting functions:

```elixir
formatter = ~f(~.3f)

formatter.(3.14159) == "3.142"
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `sigil_f` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sigil_f, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/sigil_f](https://hexdocs.pm/sigil_f).

