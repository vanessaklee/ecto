defmodule Ecto.Pool do
  @env_var 'ECTO_URI'

  alias :epgsql_pool, as: Pool

  def squery(stmt)do
    case Pool.squery(__MODULE__, stmt) do
      { :ok, count, columns, rows } -> { to_kw(columns, rows), count }
      { :ok, columns, rows } -> to_kw(columns, rows)
      { :ok, count } -> count
      other -> other
    end
  end

  def squery!(stmt) do
    case Pool.squery(__MODULE__, stmt) do
      { :ok, count, columns, rows } -> { to_kw(columns, rows), count }
      { :ok, columns, rows } -> to_kw(columns, rows)
      { :ok, count } -> count
      { :error, error } -> raise "Query failed because: #{inspect error}"
    end
  end

  def equery(stmt, args // []) do
    case Pool.equery(__MODULE__, stmt, args) do
      { :ok, count, columns, rows } -> { to_kw(columns, rows), count }
      { :ok, columns, rows } -> to_kw(columns, rows)
      { :ok, count } -> count
      other -> other
    end
  end
  
  def equery!(stmt, args // []) do
    case Pool.equery(__MODULE__, stmt, args) do
      { :ok, count, columns, rows } -> { to_kw(columns, rows), count }
      { :ok, columns, rows } -> to_kw(columns, rows)
      { :ok, count } -> count
      { :error, error } -> raise "Query failed because: #{inspect error}"
    end
  end

  defp fields(cols), do: Enum.map cols, fn
    { :column, fld, _, _, _, _ } -> fld
  end

  defp to_kw(cols, rows) do 
    cols = fields(cols)
    Enum.map rows, fn(row) ->
     List.zip [cols, tuple_to_list(row)]
    end
  end

  # for supervisor

  def child_spec do
    {pool_args, worker_args} = parse(app_env_uri || sys_env_uri)
    :epgsql_pool.child_spec __MODULE__, pool_args, worker_args
  end

  def parse(uri) do
    info = Ecto.URI.parse uri
    opts = Keyword.get info, :opts, []
    timeout = Keyword.get opts, :timeout, 3000
    opts = Keyword.delete opts, :timeout

    pool_args = Keyword.merge [ name: { :local, __MODULE__ } ], opts
    
    worker_args = Enum.map [
      hostname: info[:host],
      database: info[:db],
      username: info[:user],
      password: info[:pass],
      port:     info[:port],
      timeout:  timeout
    ], fn({k,v}) when is_binary(v) -> {k, binary_to_list(v)}; (o) -> o end

    {pool_args, worker_args}
  end

  def app_env_uri do
    case :application.get_env(Ecto, :uri) do
      { :ok, uri } -> uri
      _other -> nil
    end
  end

  def sys_env_uri, do: System.get_env("ECTO_URI")
end