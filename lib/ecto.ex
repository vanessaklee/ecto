defmodule Ecto do
  alias Validatex, as: V

  defexception RecordNotFound, [:module, :id] do
    def message(exception) do
      "could not find record #{inspect exception.module} with id #{inspect exception.id}"
    end
  end

  @doc """
  Gets a record given by the module and id.
  Returns nil if one is not found.
  """
  def get(module, id) do
    query = "#{select_from(module)} WHERE #{module.__ecto__(:primary_key)} = $1"

    case Ecto.Pool.query! query, [id] do
      { _count, [h] } -> module.__ecto__(:allocate, h)
      { 0, [] } -> nil
    end
  end

  @doc """
  Gets a record. Raises an exception if one is not found.
  """
  def get!(module, id) do
    get(module, id) || raise Ecto.RecordNotFound, module: module, id: id
  end

  @doc """
  Gets all records that matches the set of conditions.
  """
  def all(module, opts // []) do
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

    { _count, results } = Ecto.Pool.query! query, args
    lc result inlist results, do: module.__ecto__(:allocate, result)
  end

  defp select_from(module) do
    fields = module.__ecto__(:fields)
    cols   = Enum.join(Enum.map(fields, to_binary(&1)), ",")
    table  = module.__ecto__(:table)
    "SELECT #{cols} from #{table}"
  end

  @doc """
  check the table for the primary key
  """
  def exists?(record) when is_record(record) do
    module      = elem(record, 0)
    table       = module.__ecto__(:table)
    primary_key = module.__ecto__(:primary_key)
    id          = apply(module, primary_key, [record])

    if id do
      query = "SELECT EXISTS (SELECT TRUE FROM #{table} WHERE #{primary_key} = $1 LIMIT 1)"
      case Ecto.Pool.query(query, [id]) do
        { _count, [ { true } ] }  -> true
        _other                    -> false
      end
    else
      false
    end

  end

  def save(record) when is_record(record) do
    if exists?(record), do: update(record), else: create(record)
  end

  def update(record) when is_record(record) do
    module      = elem(record, 0)
    table       = module.__ecto__(:table)
    primary_key = module.__ecto__(:primary_key)
    keys        = module.__ecto__(:fields)
    returning   = returning(keys)
    values      = tl tuple_to_list(record)
    id          = apply(module, primary_key, [record])

    { keys, values, params } = generate_changes(keys, values, primary_key, [], [], [])
    kv = Enum.map_join List.zip([keys, values]), ",", fn({k, v}) -> "#{k} = #{v}" end

    query = "UPDATE #{table} SET #{kv} WHERE #{primary_key} = $#{len(params)+1} RETURNING #{returning}"
    { _count, [result] } = Ecto.Pool.query! query, params ++ [id]
    module.__ecto__(:allocate, result)
  end

  @doc """
  Saves a record issuing an insert or an
  updated based on the existance of an ID.
  """
  def create(record) when is_record(record) do
    module      = elem(record, 0)
    table       = module.__ecto__(:table)
    primary_key = module.__ecto__(:primary_key)
    keys        = module.__ecto__(:fields)
    validations = module.__ecto__(:validations)
    returning   = returning(keys)
    values      = tl tuple_to_list(record)

    plan = lc { name, validator } inlist validations do
      { name, apply(module, name, [record]), validator }
    end

    case V.validate(plan) do
      [] ->
        to_reject = if apply(module, primary_key, [record]), do: nil, else: primary_key
        { keys, values, params } = generate_changes(keys, values, to_reject, [], [], [])
        keys = Enum.join keys, ","
        values = Enum.join values, ","

        { _count, [result] } = Ecto.Pool.query! "INSERT INTO #{table} (#{keys}) VALUES (#{values}) RETURNING #{returning}", params
        module.__ecto__(:allocate, result)
      errors ->
        { :invalid, errors }
    end
  end

  def create!(record) when is_record(record) do

  end

  # Discard primary key
  defp generate_changes([pk|tk], [_|tv], pk, keys, values, params) do
    generate_changes(tk, tv, pk, keys, values, params)
  end

  defp generate_changes(tk, [nil|tv], pk, keys, values, params) do
    generate_changes(tk, [:null|tv], pk, keys, values, params)
  end

  defp generate_changes([:created_at|tk], [_|tv], pk, keys, values, params) do
    generate_changes(tk, tv, pk, [ "created_at" | keys ], [ "$#{len(params)+1}" | values ], [ "NOW()" | params ])
  end

  defp generate_changes([:updated_at|tk], [_|tv], pk, keys, values, params) do
    generate_changes(tk, tv, pk, [ "updated_at" | keys ], [ "$#{len(params)+1}" | values ], [ "NOW()" | params ])
  end

  defp generate_changes([key|tk], [p|tv], pk, keys, values, params) do
    generate_changes(tk, tv, pk, [ atom_to_binary(key) | keys ], [ "$#{len(params)+1}" | values ], [ p | params ])
  end

  defp generate_changes([], [], _pk, keys, values, params) do
    { Enum.reverse(keys), Enum.reverse(values), Enum.reverse(params) }
  end

  def where_clause(opts) do
    { where, args } =
      Enum.reduce opts, { [], [] }, fn
        { key, value }, { where, args } when is_atom(key) ->
          args = args ++ [value]
          where = [ atom_to_binary(key) <> " = $#{Enum.count args}" | where ]
          { where, args }
      end

    { " WHERE " <> Enum.join(where, " and "), args }
  end

  defp returning(cols), do: Enum.join(Enum.map(cols, to_binary(&1)), ",")

  defp len(e), do: Enum.count e

  @doc """
  Destroys a given record.
  """
  def destroy(record) do
    module      = elem(record, 0)
    primary_key = module.__ecto__(:primary_key)
    pk_value    = apply(module, primary_key, [record])

    1 == destroy(module, where: [ { primary_key, pk_value } ])
  end

  def destroy(module, [ where: opts ]) do
    table = module.__ecto__(:table)
    
    { where, args} = where_clause(opts)
    
    { count, [] } = Ecto.Pool.query "DELETE FROM #{table}#{where}", args
    count
  end
end
