defmodule Ecto.Supervisor do
	alias GenX.Supervisor, as: Sup

	def start_link do
		Sup.start_link tree
	end

	defp tree, do: Sup.OneForOne.new id: Ecto, children: [ Ecto.child_spec ]
end