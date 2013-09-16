defmodule Ecto.Worker do
  use GenServer.Behaviour

  defrecordp :state, options: nil

  def transaction(worker, txn) do
    :gen_server.call worker, { :transaction, txn }
  end

  def start_link(options) do
    :gen_server.start_link __MODULE__, options, []
  end

  def init(options) do
    Process.flag(:trap_exit, true)
    { :ok, state(options: options) }
  end

  def handle_call({ :transaction, txn }, _from, state_data) do
    state(options: options) = state_data
    result = with_conn(options, &within_transaction(&1, txn))
    { :reply, result, state_data }
  end

  defp perform_query(conn, query, params // []) do
    Ecto.Adapters.Postgres.query(conn, query, params)
  end

  defp with_conn(options, txn) do
    conn = Ecto.Adapters.Postgres.open(options)
    try do
      txn.(conn)
    after
      :ok = Ecto.Adapters.Postgres.close(conn)
    end
  end

  defp within_transaction(conn, txn) do
    { :begin, [] } = perform_query(conn, "BEGIN")
    try do
      case txn.(conn) do
        { :error, _ } = error ->
          { :rollback, [] } = perform_query(conn, "ROLLBACK")
          error
        result ->
          { :commit, [] } = perform_query(conn, "COMMIT")
          result
      end
    rescue
      exception ->
        { :rollback, [] } = perform_query(conn, "ROLLBACK")
        { :error, exception }
    end
  end
end
