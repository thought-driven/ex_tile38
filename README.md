# Tile38

This package contains convenience functions which map responses from tile38 to objects.

This package maps the `z` coordinate to the key `timestamp`.

## Peer Dependencies

- [Redix](https://github.com/whatyouhide/redix).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `tile38_client` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_tile38, ">= 0.0.0"},
    {:redix, ">= 0.0.0"}
  ]
end
```

## Usage

### Start link to Redix

Notice that we give this connection the name `tile38`.

```
{:ok, _} = Redix.start_link("redis://localhost:9851/", name: :tile38)
```

See documentation on usage at [https://hexdocs.pm/ex_tile38](https://hexdocs.pm/ex_tile38).

