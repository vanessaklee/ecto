Code.require_file "../../test_helper.exs", __FILE__

defmodule Ecto.PoolTest do
  use ExUnit.Case

  alias Ecto.Pool, as: Pool

  setup_all do
    Pool.query "CREATE TABLE txn_test(txn integer);"
    :ok
  end
  

  teardown_all do
    Pool.query "DROP TABLE txn_test;"
    :ok
  end

  test :args do
    pool_args = [ size: 5, max_overflow: 10, name: { :local, Pool }, worker_module: :pgsql_connection ]
    worker_args = [
      host:     'localhost',
      database: "db",
      user:     "user",
      password: "pass",
      port:     5432
    ]
    
    uri = "ecto+postgres://user:pass@localhost/db?timeout=5000&size=5&overflow=10"
    { actual_pool_args, actual_worker_args } = Pool.parse uri
    assert Keyword.equal? pool_args, actual_pool_args
    assert Keyword.equal? worker_args, actual_worker_args
  end

  test :transaction do
    assert { :error, RuntimeError[message: "Foo!"] } == Pool.transaction fn(conn) ->
      Pool.query(conn, "insert into txn_test(txn) values(1)")
      raise "Foo!"
    end

    assert { 1, [] } == Pool.transaction fn(conn) ->
      Pool.query(conn, "insert into txn_test(txn) values(1)")
      Pool.query(conn, "insert into txn_test(txn) values(2)")
    end

    assert { :error, :bad_match } == Pool.transaction fn(conn) ->
      Pool.query(conn, "select 1+1")
      raise :bad_match
    end
  end

  test :query_error_message do
    assert "Query failed because :foo\nSTMT" == Ecto.QueryError[reason: :foo, stmt: "STMT"].message
  end
end
