# Ecto

Ecto is a simple wrapper for epgsql_pool. Loads up a pool
based on connection info found in env var ECTO_URI

    ecto://user:pass@host/db?size=x&overflow=y

start it up by

```sh
mix deps.get
mix test
ECTO_URI=<connection info> iex -S mix
```

then run

```elixir
iex(1)> Ecto.squery "select true"
{:ok,[{:column,"bool",:bool,1,-1,0}],[{"t"}]}
```
