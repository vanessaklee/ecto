Code.require_file "../../test_helper.exs", __FILE__

defmodule EctoServerTest do
  use ExUnit.Case

  test :args do
    pool_args = [ size: 5, max_overflow: 10, name: { :local, Ecto} ]
    worker_args = [
      hostname: 'localhost',
      database: 'db',
      username: 'user',
      password: 'pass',
      port:     5432,
      timeout:  5000
    ]
    
    uri = "ecto://user:pass@localhost/db?timeout=5000&size=5&overflow=10"
    {actual_pool_args, actual_worker_args} = Ecto.Server.args uri
    assert Keyword.equal? pool_args, actual_pool_args
    assert Keyword.equal? worker_args, actual_worker_args
  end
end
