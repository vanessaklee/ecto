defexception Ecto.ParseError, [reason: nil, uri: nil] do
	def message(Ecto.ParseError[reason: reason, uri: uri]) do
		"error parsing #{uri}: #{reason}"
	end
end
