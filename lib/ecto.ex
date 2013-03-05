defmodule Ecto do
  import GenX.GenServer
  use Application.Behaviour

  alias :epgsql_pool, as: PG

  def squery(stmt), do: PG.squery(@name, stmt)
  def equery(stmt, args), do: PG.equery(@name, stmt, args)

  def start(_type, _args) do
    start
  end

  def start do
    Ecto.Supervisor.start_link
  end

  def stop(_state) do
    :ok
  end

end
