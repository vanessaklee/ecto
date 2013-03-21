Code.require_file "../../test_helper.exs", __FILE__

defmodule EctoPoolTest do
  use ExUnit.Case

  alias Ecto.Pool, as: Pool

  test :args do
    pool_args = [ size: 5, max_overflow: 10, name: { :local, Ecto.Pool}, worker_module: :pgsql_connection ]
    worker_args = [
      host:     'localhost',
      database: 'db',
      user:     'user',
      password: 'pass',
      port:      5432
    ]
    
    uri = "ecto+postgres://user:pass@localhost/db?timeout=5000&size=5&overflow=10"
    {actual_pool_args, actual_worker_args} = Pool.parse uri
    assert Keyword.equal? pool_args, actual_pool_args
    assert Keyword.equal? worker_args, actual_worker_args
  end

  test :name_in_uri do
    uri = "ecto+postgres://user:pass@localhost/db?timeout=5000&size=5&overflow=10&name=gary"
    {pool_args, _} = Pool.parse uri
    assert { :local, :gary } == Keyword.get pool_args, :name
  end

  test :uri do
    :application.set_env(:ecto, :uri, "APP_ENV")
    assert "APP_ENV" == Pool.default_uri
  end

  test :query_error_message do
    assert "Query failed because :foo\nSTMT" == Ecto.QueryError[reason: :foo, stmt: "STMT"].message
  end
end
