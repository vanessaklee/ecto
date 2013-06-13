Code.require_file "../test_helper.exs", __FILE__

defmodule EctoTestCase do
  use ExUnit.Case, async: true

  test :where_clause do
    opts = [
      { :foo, ">=", :biz},
      { :biz, :baz }
    ]
    
    assert { " WHERE ( biz = $2 ) AND ( foo >= $1 )", [ :biz, :baz ] } == Ecto.where_clause(opts)
  end

  test :map_query do
    stmt = "SELECT 1, 2, 3"
    mapper = fn({x,y,z}) -> { x * 2, y * 2, z * 2 } end
    assert Ecto.map(stmt, mapper) == [ { 2, 4, 6 } ]

    stmt = "SELECT true = $1"
    mapper = fn({r}) -> not r end
    assert Ecto.map(stmt, [false], mapper) == [ true ]
  end
end