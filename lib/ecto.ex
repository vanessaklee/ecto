defmodule Ecto do
	import GenX.GenServer
	use Application.Behaviour

	alias :epgsql_pool, as: PG

	@name Ecto
	@env_var 'ECTO_URI'

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

	def child_spec do
    {pool_args, worker_args} = args System.get_env(@env_var)
    :epgsql_pool.child_spec @name, pool_args, worker_args
	end

	def args(uri) do
		info = URI.Ecto.parse uri
		opts = Keyword.get info, :opts, []
	  timeout = Keyword.get opts, :timeout, 3000
	  opts = Keyword.delete opts, :timeout

	  pool_args = Keyword.merge [ name: { :local, @name } ], opts
    
    worker_args = Enum.map [
    	hostname: Keyword.get(info, :host),
    	database: Keyword.get(info, :db),
    	username: Keyword.get(info, :user),
    	password: Keyword.get(info, :pass),
    	port:     Keyword.get(info, :port),
    	timeout:  timeout
    ], fn({k,v}) when is_binary(v) -> {k, binary_to_list(v)}; (o) -> o end

		{pool_args, worker_args}
	end

end
