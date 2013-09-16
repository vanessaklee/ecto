defmodule Ecto.Adapters.Postgres do
  def open(options) do
    { :ok, conn } = :pgsql_connection.start_link(options)
    conn
  end

  def close(conn) do
    :pgsql_connection.close({ :pgsql_connection, conn })
  end

  def query(conn, query, params) do
    :pgsql_connection.extended_query(query, params, { :pgsql_connection, conn })
  end
end
