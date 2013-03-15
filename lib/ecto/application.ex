defmodule Ecto.Application do
  use Application.Behaviour

  @app :ecto

  def start, do: :application.start(@app)
  def start(_type, _args), do: Ecto.Supervisor.start_link
  def stop, do: :application.stop(@app)
  def stop(_state), do: :ok

  def started? do
    apps = Enum.map :application.which_applications, fn
      {name, _desc, _version} -> name
    end
    List.member? apps, @app
  end
end