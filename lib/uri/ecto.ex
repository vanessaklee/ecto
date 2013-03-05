defmodule URI.Ecto do
	@behavior URI.Parser
	alias Ecto.ParseError, as: ParseError
	
	def default_port(), do: 5432

	def parse(<<"ecto://", rest :: binary>> = uri) do
		info = [ host: nil, port: 5432, db: nil, user: nil, pass: nil ]
		case parse_user(rest, "", info) do
			{:error, reason} -> raise ParseError.new uri: uri, reason: reason
			success -> success
		end
	end

	def parse(uri) do
		raise Ecto.ParseError.new reason: "uri must begin with ecto://", uri: uri
	end

	#if we get this far with an empty accumulator
	#then the url doesn't have a user:pass segment
	defp parse_user(<<?/, rest :: binary>>, <<>>, info) do
		parse_host(rest, "", info)
	end

	# if we get this far and hit a slash we have been parsing
	# the host
	defp parse_user(<<?/, rest :: binary>>, acc, info) do
		parse_host(<<?/, rest :: binary>>, acc, info)
	end
	
	# we've got the user, but no password, so move on to
	# parsing the host name
	defp parse_user(<<?@, rest :: binary>>, acc, info) do
		info = Keyword.put info, :user, acc
		parse_host(rest, <<>>, info)
	end

	defp parse_user(<<?:, _rest :: binary>>, "", _info) do
		{:error, "user expected"}
	end

	defp parse_user(<<?:, rest :: binary>>, acc, info) do
		info = Keyword.put info, :user, acc
		parse_pass(rest, <<>>, info)
	end

	defp parse_user(<<c, rest :: binary>>, acc, info) do
		parse_user(rest, <<acc :: binary, c>>, info)
	end


	# parse the password segment of the url
	defp parse_pass(<<?@, _rest :: binary>>, "", _info) do
		{:error, "password expected"}
	end
	
	defp parse_pass(<<?@, rest :: binary>>, acc, info) do
		info = Keyword.put info, :pass, acc
		parse_host(rest, <<>>, info)
	end

	defp parse_pass(<<c, rest :: binary>>, acc, info) do
		parse_pass(rest, <<acc :: binary, c>>, info)
	end


	# parse the host segment of the url
	defp parse_host(<<?/, _rest :: binary>>, "", _info) do
		{:error, "host expected"}
	end
	defp parse_host(<<?/, rest :: binary>>, acc, info) do
		info = Keyword.put info, :host, acc
		parse_db(rest, <<>>, info)
	end

	defp parse_host(<<c, rest :: binary>>, acc, info) do
		parse_host(rest, <<acc :: binary, c>>, info)
	end

	defp parse_host("", _acc, _info) do
		{:error, "database expected"}
	end

	# end of the string means no more to parse
	# done with all parsing
	defp parse_db("", acc, info) do
		Keyword.put info, :db, acc
	end

	defp parse_db(<<??, _opts :: binary>>, "", _info) do
		{:error, "database expected"}
	end

	defp parse_db(<<??, opts :: binary>>, acc, info) do
		info = Keyword.put info, :db, acc
		parse_opts(opts, info)
	end

	defp parse_db(<<c, rest :: binary>>, acc, info) do
		parse_db(rest, <<acc :: binary, c>>, info)
	end

	# no options...no problem
	defp parse_opts("", info) do
		info
	end

	defp parse_opts(opts, info) do
		opts = String.split(opts, "&")
		opts = Enum.map(opts, String.split &1, "=")
			|> Enum.map(opt(&1))
			|> Enum.filter &1 != nil
		Keyword.put info, :opts, opts
	end

	defp opt(["size", size]), do: {:size, binary_to_integer(size)}
	defp opt(["overflow", overflow]), do: {:max_overflow, binary_to_integer(overflow)}
	defp opt(["timeout", timeout]), do: {:timeout, binary_to_integer(timeout)}
	defp opt([_, _]), do: nil
end
