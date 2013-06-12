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
end