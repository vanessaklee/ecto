defexception Ecto.QueryError, reason: nil, stmt: nil, args: nil do
  def message(Ecto.QueryError[reason: reason, stmt: stmt, args: nil]) do
    "Query failed because #{inspect reason}\n#{stmt}"
  end
  def message(Ecto.QueryError[reason: reason, stmt: stmt, args: args]) do
    "Query failed because #{inspect reason}\n#{stmt}\n#{inspect args}"
  end
end

defmodule Ecto.Pool do
  @env_var "ECTO_URI"

  def start_link, do: start_link(default_uri)
  def start_link(uri) do
    { pool_args, worker_args } = parse(uri)
    :poolboy.start_link(pool_args, worker_args)
  end

  def query(stmt), do: query(__MODULE__, stmt, [])

  def query(stmt, args) when is_binary(stmt), do: query(__MODULE__, stmt, args)
  def query(pool, stmt), do: query(pool, stmt, [])

  def query(pool, stmt, args) when is_atom(pool) and is_binary(stmt) and is_list(args) do
    case do_query(pool, stmt, args) do
      { { :insert, _, count }, rows } -> { count, rows }
      { { :select, count }, rows }    -> { count, rows }
      { { :update, count }, rows }    -> { count, rows }
      { { :delete, count }, rows }    -> { count, rows }
      { { :create, :table }, _ }      -> :ok
      { { :drop, :table }, _ }        -> :ok
      { :error, error }               -> { :error, error }
    end
  end

  def query!(stmt), do: query!(__MODULE__, stmt, [])

  def query!(stmt, args) when is_binary(stmt), do: query!(__MODULE__, stmt, args)
  def query!(pool, stmt), do: query!(pool, stmt, [])

  def query!(pool, stmt, args) when is_atom(pool) and is_binary(stmt) and is_list(args) do
    case query(pool, stmt, args) do
      { :error, reason } -> raise Ecto.QueryError[reason: reason, stmt: stmt, args: args]
      other              -> other
    end
  end

  defp do_query(pool, stmt, args) do
    :poolboy.transaction pool, fn(conn) ->
      :pgsql_connection.extended_query(stmt, args, { :pgsql_connection, conn })
    end
  end

  # for supervisor

  def parse(uri) do
    info = Ecto.URI.parse uri
    opts = Keyword.get info, :opts, []

    opts = Keyword.delete opts, :timeout

    name = Keyword.get opts, :name, __MODULE__
    opts = Keyword.delete opts, :name

    pool_args = Keyword.merge [ name: { :local, name }, worker_module: :pgsql_connection ], opts
    
    worker_args = [
      host:     binary_to_list(info[:host]),
      database: info[:db],
      user:     info[:user],
      password: info[:pass],
      port:     info[:port]
    ]

    { pool_args, worker_args }
  end

  def default_uri do
    case :application.get_env(:ecto, :uri) do
      { :ok, uri } -> uri
      _other -> System.get_env(@env_var)
    end
  end
end