defmodule Ecto.Application do
  use Application.Behaviour

  def start, do: :application.start(:ecto)
  def start(_type, _args), do: Ecto.Supervisor.start_link
  def stop(_state), do: :ok
end