Code.require_file "../../test_helper.exs", __FILE__

defmodule EctoPoolTest do
  use ExUnit.Case

  alias Ecto.Pool, as: Pool

  test :args do
    pool_args = [ size: 5, max_overflow: 10, name: { :local, Ecto.Pool} ]
    worker_args = [
      hostname: 'localhost',
      database: 'db',
      username: 'user',
      password: 'pass',
      port:     5432,
      timeout:  5000
    ]
    
    uri = "ecto://user:pass@localhost/db?timeout=5000&size=5&overflow=10"
    {actual_pool_args, actual_worker_args} = Pool.parse uri
    assert Keyword.equal? pool_args, actual_pool_args
    assert Keyword.equal? worker_args, actual_worker_args
  end

  test :uri do
    :application.set_env(Ecto, :uri, "APP_ENV")
    System.put_env("ECTO_URI", "SYS_ENV")
    assert "APP_ENV" == Pool.app_env_uri
    assert "SYS_ENV" == Pool.sys_env_uri
  end
end
