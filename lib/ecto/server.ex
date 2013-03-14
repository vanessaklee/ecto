defmodule Ecto.Server do
  @env_var 'ECTO_URI'

  def child_spec do
    {pool_args, worker_args} = parse(app_env_uri || sys_env_uri)
    :epgsql_pool.child_spec Ecto.pool, pool_args, worker_args
  end

  def parse(uri) do
    info = Ecto.URI.parse uri
    opts = Keyword.get info, :opts, []
    timeout = Keyword.get opts, :timeout, 3000
    opts = Keyword.delete opts, :timeout

    pool_args = Keyword.merge [ name: { :local, Ecto.pool } ], opts
    
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