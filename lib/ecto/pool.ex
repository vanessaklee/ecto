defexception Ecto.QueryError, reason: nil, stmt: nil, args: nil do
  def message(Ecto.QueryError[reason: reason, stmt: stmt, args: nil]) do
    "Query failed because #{inspect reason}\n#{stmt}"
  end
  def message(Ecto.QueryError[reason: reason, stmt: stmt, args: args]) do
    "Query failed because #{inspect reason}\n#{stmt}\n#{inspect args}"
  end
end

defmodule Ecto.Pool do
  alias :poolboy, as: Poolboy

  def start_link, do: start_link uri
  def start_link(uri) do
    { pool_args, worker_args } = parse(uri)
    :poolboy.start_link(pool_args, worker_args)
  end

  @doc """
  Execute query
  """
  def query(stmt) when is_binary(stmt) do
    transaction &query(&1, stmt)
  end

  def query(stmt, args) when is_binary(stmt) and is_list(args) do
    transaction &query(&1, stmt, args)
  end

  def query(conn, stmt, args // []) when is_pid(conn) and is_binary(stmt) and is_list(args) do
    case Ecto.Adapters.Postgres.query(conn, stmt, args) do
      { { :insert, _, count }, rows } -> { count, rows }
      { { :select, count }, rows }    -> { count, rows }
      { { :update, count }, rows }    -> { count, rows }
      { { :delete, count }, rows }    -> { count, rows }
      { { :create, :table }, _ }      -> :ok
      { { :drop, :table }, _ }        -> :ok
      { :begin, [] }                  -> :ok
      { :commit, [] }                 -> :ok
      { :rollback, [] }               -> :ok
      { :error, error }               -> { :error, error }
    end
  end

  @doc """
  Executes a query in a transaction
  Raises Ecto.QueryError on 
  """
  def query!(stmt) when is_binary(stmt) do
    transaction! &query!(&1, stmt)
  end

  def query!(stmt, args) when is_binary(stmt) and is_list(args) do
    transaction! &query!(&1, stmt, args)
  end

  def query!(conn, stmt, args // []) when is_pid(conn) and is_binary(stmt) and is_list(args) do
    case query(conn, stmt, args) do
      { :error, reason } -> raise Ecto.QueryError[reason: reason, stmt: stmt, args: args]
      other              -> other
    end
  end

  def transaction(txn) do
    Poolboy.transaction __MODULE__, &Ecto.Worker.transaction(&1, txn)
  end

  def transaction!(txn) do
    Poolboy.transaction __MODULE__, fn(worker) ->
      case Ecto.Worker.transaction(worker, txn) do
        { :error, exception } when is_exception(exception) ->
          raise exception
        result -> result
      end
    end
  end

  def parse(uri) do
    info = Ecto.URI.parse uri
    opts = Keyword.get info, :opts, []

    opts = Keyword.delete opts, :timeout

    pool_args = Keyword.merge [ name: { :local, __MODULE__ }, worker_module: Ecto.Worker ], opts
    
    worker_args = [
      host:     binary_to_list(info[:host]),
      database: info[:db],
      user:     info[:user],
      password: info[:pass],
      port:     info[:port]
    ]

    { pool_args, worker_args }
  end

  def uri do
    case :application.get_env(:ecto, :uri) do
      { :ok, uri } -> uri
      _other -> System.get_env("ECTO_URI")
    end
  end
end
