defmodule Ecto.Supervisor do
  @moduledoc """
  Supervises each ecto pool to make it easier to start up a new one
  """
  use Supervisor.Behaviour

  def start_link() do
    :supervisor.start_link({ :local, __MODULE__ }, __MODULE__, [])
  end

  def init(_) do
    supervise children, strategy: :simple_one_for_one
  end

  def children do
    [ worker(Ecto.Pool, [], restart: :transient) ]
  end

  def start_child do
    :supervisor.start_child(__MODULE__, [])
  end

  def start_child(uri) do
    :supervisor.start_child(__MODULE__, [uri])
  end
end