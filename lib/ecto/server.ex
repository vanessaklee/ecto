defmodule Ecto.Server do
  @name Ecto
  @env_var 'ECTO_URI'

  def child_spec do
    {pool_args, worker_args} = args System.get_env(@env_var)
    :epgsql_pool.child_spec @name, pool_args, worker_args
  end

  def args(uri) do
    info = Ecto.URI.parse uri
    opts = Keyword.get info, :opts, []
    timeout = Keyword.get opts, :timeout, 3000
    opts = Keyword.delete opts, :timeout

    pool_args = Keyword.merge [ name: { :local, @name } ], opts
    
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
end