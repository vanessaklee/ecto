defmodule Ecto do
  import GenX.GenServer
  use Application.Behaviour

  @pool Ecto

  alias :epgsql_pool, as: PG

  def pool, do: @pool
  def squery(stmt), do: PG.squery(pool, stmt)
  def equery(stmt, args), do: PG.equery(pool, stmt, args)



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
