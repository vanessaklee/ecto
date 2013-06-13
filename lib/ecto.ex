defmodule Ecto do
  alias Validatex, as: V
  alias Ecto.Pool, as: Pool

  defexception RecordNotFound, [:module, :id] do
    def message(exception) do
      "could not find record #{inspect exception.module} with id #{inspect exception.id}"
    end
  end

  defexception RecordInvalid, [:errors] do
    def message(exception) do
      "Validation failed: #{inspect exception.errors}"
    end
  end

  @doc """
  Gets a record given by the module and id.
  Returns nil if one is not found.
  """
  def get(module, id) when is_atom(module) do
    Pool.transaction fn(conn) -> get(conn, module, id) end
  end
  
  def get(conn, module, id) when is_pid(conn) and is_atom(module) do
    get(conn, module, id, :query)
  end

  def get(conn, module, id, query_fun) when is_pid(conn) and is_atom(module) and is_atom(query_fun) do
    query = "#{select_from(module)} WHERE #{module.__ecto__(:primary_key)} = $1 LIMIT 1"

    case apply(Pool, query_fun, [conn, query, [id]]) do
      { 0, _ } -> nil
      { _, [h] } -> module.__ecto__(:allocate, null_to_nil(h))
    end
  end

  @doc """
  Gets a record. Raises an exception if one is not found.
  """
  def get!(module, id) when is_atom(module) do
    Pool.transaction! fn(conn) -> 
      get(conn, module, id, :query!) || raise Ecto.RecordNotFound, module: module, id: id
    end
  end

  @doc """
  Gets all records that matches the set of conditions.
  """
  def all(module) when is_atom(module), do: all(module, [])
  def all(module, opts) when is_atom(module) do
    Pool.transaction fn(conn) -> all(conn, module, opts) end
  end
  
  def all(conn, module, opts) when is_pid(conn) and is_atom(module) and is_list(opts) do
    query = select_from(module)
    args = []

    if where = opts[:where] do
      { where, args } = where_clause(where)
      query = query <> where
    end

    query =
      case opts[:order_by] do
        nil ->
          query
        order_by when is_atom(order_by) ->
          query <> " ORDER BY #{order_by}"
        { order_by, asc_or_desc } when is_atom(order_by) and asc_or_desc in [:asc, :desc] ->
          query <> " ORDER BY #{order_by} #{asc_or_desc}"
      end

    if (limit = opts[:limit]) && is_integer(limit) do
      query = query <> " LIMIT #{limit}"
    end

    { _count, results } = Pool.query(conn, query, args)
    lc result inlist results, do: module.__ecto__(:allocate, null_to_nil(result))
  end

  defp select_from(module) do
    fields = module.__ecto__(:fields)
    cols   = Enum.join(Enum.map(fields, to_binary(&1)), ",")
    table  = module.__ecto__(:table)
    "SELECT #{cols} FROM #{table}"
  end

  @doc """
  check the table for the primary key
  """
  def exists?(record) when is_record(record) do
    Pool.transaction fn(conn) -> exists?(conn, record) end
  end
  
  def exists?(conn, record) when is_pid(conn) and is_record(record) do
    module      = elem(record, 0)
    table       = module.__ecto__(:table)
    primary_key = module.__ecto__(:primary_key)
    id          = apply(module, primary_key, [record])

    if id do
      query = "SELECT EXISTS (SELECT TRUE FROM #{table} WHERE #{primary_key} = $1 LIMIT 1)"
      case Pool.query(conn, query, [id]) do
        { _count, [ { true } ] }  -> true
        _other                    -> false
      end
    else
      false
    end

  end

  def valid?(record) when is_record(record) do
    module      = elem(record, 0)
    validations = module.__ecto__(:validations)

    plan = lc { name, validator } inlist validations do
      { name, apply(module, name, [record]), validator }
    end

    V.validate(plan) == []
  end


  def save(record) when is_record(record) do
    Pool.transaction fn(conn) -> save(conn, record) end
  end

  def save(conn, record) when is_pid(conn) and is_record(record) do
    if exists?(conn, record), do: update(conn, record), else: create(conn, record)
  end


  def save!(record) when is_record(record) do
    Pool.transaction! fn(conn) -> save!(conn, record) end
  end

  def save!(conn, record) when is_pid(conn) and is_record(record) do
    if exists?(conn, record), do: update!(conn, record), else: create!(conn, record)
  end


  def update(record) when is_record(record) do
    Pool.transaction fn(conn) -> update(conn, record) end
  end

  def update(conn, record) when is_pid(conn) and is_record(record) do
    update(conn, record, :query)
  end


  def update!(record) when is_record(record) do
    Pool.transaction! fn(conn) -> update!(conn, record) end
  end
  
  def update!(conn, record) when is_pid(conn) and is_record(record) do
    case update(conn, record, :query!) do
      { :invalid, Errors } ->
        raise Ecto.RecordInvalid[ errors: Errors ]
      valid ->
        valid
    end
  end


  def update(conn, record, query_fun) when is_pid(conn) and is_record(record) and is_atom(query_fun) do
    module      = elem(record, 0)
    validations = module.__ecto__(:validations)

    plan = lc { name, validator } inlist validations do
      { name, apply(module, name, [record]), validator }
    end

    case V.validate(plan) do
      [] ->
        table       = module.__ecto__(:table)
        primary_key = module.__ecto__(:primary_key)
        keys        = module.__ecto__(:fields)
        skip        = module.__ecto__(:skip_on_update)
        returning   = returning(keys)
        values      = tl tuple_to_list(record)
        id          = apply(module, primary_key, [record])
        { keys, values, params } = generate_changes(keys, values, skip, [], [], [])
        kv = Enum.map_join List.zip([keys, values]), ",", fn({k, v}) -> "#{k} = #{v}" end

        query = "UPDATE #{table} SET #{kv} WHERE #{primary_key} = $#{len(params)+1} RETURNING #{returning}"
        { _count, [result] } = apply( Pool, query_fun, [ conn, query, params ++ [id] ] )
        module.__ecto__(:allocate, null_to_nil(result))
      errors ->
        { :invalid, errors }
    end
  end

  @doc """
  Saves a record issuing an insert or an
  updated based on the existance of an ID.
  """
  def create(record) when is_record(record) do
    Pool.transaction fn(conn) -> create(conn, record) end
  end
  
  def create(conn, record) when is_pid(conn) and is_record(record) do
    create(conn, record, :query)
  end

  
  def create!(record) when is_record(record) do
    Pool.transaction! fn(conn) -> create!(conn, record) end
  end
  
  def create!(conn, record) when is_pid(conn) and is_record(record) do
    case create(conn, record, :query!) do
      { :invalid, errors } ->
        raise Ecto.RecordInvalid.new errors: errors
      valid ->
        valid
    end
  end

  
  def create(conn, record, query_fun) when is_pid(conn) and is_record(record) and is_atom(query_fun) do
    module      = elem(record, 0)
    validations = module.__ecto__(:validations)

    plan = lc { name, validator } inlist validations do
      { name, apply(module, name, [record]), validator }
    end

    case V.validate(plan) do
      [] ->
        table       = module.__ecto__(:table)
        primary_key = module.__ecto__(:primary_key)
        keys        = module.__ecto__(:fields)
        returning   = returning(keys)
        values      = tl tuple_to_list(record)

        skip = if apply(module, primary_key, [record]), do: nil, else: [primary_key]
        { keys, values, params } = generate_changes(keys, values, skip, [], [], [])
        keys = Enum.join keys, ","
        values = Enum.join values, ","

        { _count, [result] } = apply(Pool, query_fun, [conn, "INSERT INTO #{table} (#{keys}) VALUES (#{values}) RETURNING #{returning}", params])
        module.__ecto__(:allocate, null_to_nil(result))
      errors ->
        { :invalid, errors }
    end
  end

  defp null_to_nil(t) when is_tuple(t), do: null_to_nil(tuple_to_list(t),[])
  defp null_to_nil([],acc),             do: list_to_tuple Enum.reverse(acc)
  defp null_to_nil([:null|t],acc),      do: null_to_nil(t, [nil|acc])
  defp null_to_nil([o|t], acc),         do: null_to_nil(t, [o|acc])

  # Discard primary key
  defp generate_changes([k|tk], [_|tv], [k|ts], keys, values, params) do
    generate_changes(tk, tv, ts, keys, values, params)
  end

  defp generate_changes(tk, [nil|tv], sk, keys, values, params) do
    generate_changes(tk, [:null|tv], sk, keys, values, params)
  end

  defp generate_changes([:created_at|tk], [_|tv], sk, keys, values, params) do
    generate_changes(tk, tv, sk, [ "created_at" | keys ], [ "$#{len(params)+1}" | values ], [ "NOW()" | params ])
  end

  defp generate_changes([:updated_at|tk], [_|tv], sk, keys, values, params) do
    generate_changes(tk, tv, sk, [ "updated_at" | keys ], [ "$#{len(params)+1}" | values ], [ "NOW()" | params ])
  end

  defp generate_changes([key|tk], [p|tv], sk, keys, values, params) do
    generate_changes(tk, tv, sk, [ atom_to_binary(key) | keys ], [ "$#{len(params)+1}" | values ], [ p | params ])
  end

  defp generate_changes([], [], _sk, keys, values, params) do
    { Enum.reverse(keys), Enum.reverse(values), Enum.reverse(params) }
  end

  def where_clause(opts) do  
    opts = Enum.map opts, fn
      { key, value }     -> { key, "=", value }
      { key, op, value } -> { key, op, value }
    end

    { where, args } =  
      Enum.reduce opts, { [], [] }, fn
        { key, op, value }, { where, args } ->
          args = args ++ [value]
          clause = Enum.join(["(", key, op, "$#{Enum.count args}", ")"], " ")
          where = [ clause | where ]
          { where, args }
      end
    { " WHERE " <> Enum.join(where, " AND "), args }
  end

  defp returning(cols), do: Enum.join(Enum.map(cols, to_binary(&1)), ",")

  defp len(e), do: Enum.count e

  @doc """
  Destroys a given record.
  """
  def destroy(record) when is_record(record) do
    Pool.transaction fn(conn) -> destroy(conn, record) end
  end

  def destroy(conn, record) when is_pid(conn) and is_record(record) do
    module      = elem(record, 0)
    primary_key = module.__ecto__(:primary_key)
    pk_value    = apply(module, primary_key, [record])

    1 == destroy(conn, module, where: [ { primary_key, pk_value } ])
  end

  def destroy(module, opts) when is_atom(module) and is_list(opts) do
    Pool.transaction fn(conn) -> destroy(conn, module, opts) end
  end

  def destroy(conn, module, [ where: opts ]) when is_pid(conn) and is_atom(module) and is_list(opts) do
    table = module.__ecto__(:table)
    
    { where, args} = where_clause(opts)
    
    { count, [] } = Pool.query conn, "DELETE FROM #{table}#{where}", args
    count
  end

  def map(stmt, args // [], mapper) do
    case Ecto.Pool.query(stmt, args) do
      { :error, error } -> { :error, error }
      { 0, _rows }      -> []
      { _count, rows }  -> Enum.map rows, mapper
    end
  end
end
