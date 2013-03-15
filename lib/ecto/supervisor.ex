defmodule Ecto.Supervisor do
  alias GenX.Supervisor, as: Sup
  alias Ecto.Pool, as: Pool

  def start_link do
    Sup.start_link Sup.OneForOne.new(id: Ecto, children: [ Pool.child_spec ])
  end
end