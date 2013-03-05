# Ecto

Ecto is a simple wrapper for epgsql_pool. Loads up a pool
based on connection info found in env var ECTO_URI

	ecto://user:pass@host/db?size=x&overflow=y
