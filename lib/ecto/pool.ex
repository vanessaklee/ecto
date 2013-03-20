defmodule Ecto.Pool do
  @env_var 'ECTO_URI'

  def start_link, do: start_link(default_uri)
  def start_link(uri) do
    {pool_args, worker_args} = parse(uri)
    :poolboy.start_link(pool_args, worker_args)
  end

  def query(stmt, args // []), do: query(__MODULE__, stmt, args)

  def query(pool, stmt, args // []) do
    case _equery(pool, stmt, args) do
      { { :insert, _, count }, rows } -> { rows, count }
      { { :select, count }, rows }    -> { rows, count }
      { { :update, count }, rows }    -> { rows, count }
      { { :delete, count }, rows }    -> { rows, count }
      other -> other
    end
  end

  def query!(stmt, args // []), do: query!(__MODULE__, stmt, args)

  def query!(pool, stmt, args // []) do
    case _equery(pool, stmt, args) do
      { { :insert, _, count }, rows } -> { rows, count }
      { { :select, count }, rows }    -> { rows, count }
      { { :update, count }, rows }    -> { rows, count }
      { { :delete, count }, rows }    -> { rows, count }
      { :error, error } -> raise "Query failed because: #{inspect error}"
    end
  end

  defp _equery(pool, stmt, args) do
    :poolboy.transaction(pool, fn(conn) ->
      :pgsql_connection.extended_query(stmt, args, { :pgsql_connection, conn })
    end)
  end

  # for supervisor

  def parse(uri) do
    info = Ecto.URI.parse uri
    opts = Keyword.get info, :opts, []

    opts = Keyword.delete opts, :timeout

    name = Keyword.get opts, :name, __MODULE__
    opts = Keyword.delete opts, :name

    pool_args = Keyword.merge [ name: { :local, name }, worker_module: :pgsql_connection ], opts
    
    worker_args = Enum.map [
      host: info[:host],
      database: info[:db],
      user: info[:user],
      password: info[:pass],
      port:     info[:port]
    ], fn({k,v}) when is_binary(v) -> {k, binary_to_list(v)}; (o) -> o end

    {pool_args, worker_args}
  end

  def default_uri do
    case :application.get_env(Ecto, :uri) do
      { :ok, uri } -> uri
      _other -> System.get_env("ECTO_URI")
    end
  end
end