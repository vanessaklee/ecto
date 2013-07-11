# Ecto

Ecto is a simplistic data mapper to postgresql. It provides useful macros
for defining Modules and mapping them to a database table. Communication
to postgres is done via poolboy + pgsql.

## Getting ecto

Clone it via `git clone git@github.com/interline/ecto.git`
Mix it up like this
```shell
$ mix deps.get
* Updating pgsql (17) [git: "https://github.com/semiocast/pgsql.git"]
...
$ mix compile
```

## Starting ecto

Ecto comes with a simple_one_for_one supervisor which can be supervised in an
application supervision tree. Calling `Ecto.Supervisor.start_link` will start
it up just as you'd exptect. Once the supervisor is started, calling 
`Ecto.Supervisor.start_child uri` will start a supervised connection pool.

A connection pool can also be started with `Ecto.Pool.start_link [uri]`. If no
uri is provided, ecto will try to find one in
`:application.get_env(:ecto, :uri)`. If nothing is found there, Ecto
uses the value found in `Sytem.get_env("ECTO_URI")`. Ecto will ungracefully fail
to load if no valid uri is found.

A valid uri takes the form of `ecto+postgres://user:passwor@host/db?size=x&overflow=y`.

## Testing ecto

Ecto must be started to run tests, and as noted above, Ecto needs a valid uri to
start. Also, Ecto needs to be able to create and drop a test table, so be sure to
connect with user that has the proper priviledges.

For local testing I've been using [Postgres.app](http://postgresapp.com/), but
you can run tests agains any running postgres instance.

## Defining models

```elixir
defmodule MyModel
  use Ecto.Model

  table_name :my_table
  primary_key :id  # can be any column, but should appear before other fields
  field :col1
  field :col2
  field :col3
  field :some_other_column
end
```

This will create an Elixir Record that contains the metadata that Ecto needs
to look up save, update, lookup rows, etc.

**NOTE** *Model* is a loaded term and probably a bad name for this. Don't confuse Ecto with an ORM, cuz it isn't
one.

## Saving a record

Once your models have been defined you can save them like this:

```elixir
Ecto.save MyModel[id: 1, col1: "foo", col2: 14, col3: false, some_other_column: nil]
#=> MyModel[id: 1, col1: "foo", col2: 14, col3: false, some_other_column: nil]
```

`Ecto.save` will issue an INSERT statement if the primary key does not exists in the
table, otherwise an UPDATE statement will be sent. All columns will be sent

## Fetching a record

Ecto provides 2 method for getting records `get` and `get!`. The first returns
nil if the record is not found, `get!` raises an exception if the record is
not found.

```elixir
Ecto.get MyModel, 1
#=> MyModel[id: 1, col1: "foo", col2: 14, col3: false, some_other_column: nil]

some_id = 5555
Ecto.get! MyModel, some_id
#=> ** (Ecto.RecordNotFound) could not find record MyModel with id 555...
```

## Destroying a record

```elixir
Ecto.destroy MyModel[id: 1]
#=> 1
```

## todo

- Add adapters for different backends (redis, elastic?)
- Some other cool stuff that hasn't been even been invented...yet
