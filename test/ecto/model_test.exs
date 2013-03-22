Code.require_file "../../test_helper.exs", __FILE__

defmodule TestModel do
  use Ecto.Model
  table_name :ecto_test
  primary_key :id
  field :version
end

defmodule EctoModelTest do
  use ExUnit.Case

  setup_all do
    Ecto.Pool.start_link
    Ecto.Pool.query %b;
      CREATE TABLE ecto_test ( id serial primary key, version int );
    :ok
  end

  teardown_all do
    Ecto.Pool.query "drop table ecto_test"
    :ok
  end

  test :create do
    model = Ecto.save TestModel[version: 1]
    assert model.id != nil
    assert_raise Ecto.QueryError, fn ->
      Ecto.create model
    end
  end

  test "cannot create with existing id" do
    model = TestModel[id: 22, version: 1]
    Ecto.create model
  end

  test :update do
    model = Ecto.save TestModel[version: 100]
    version2 = model.version 2
    assert version2 == Ecto.save(version2)
  end

  test :destroy do
    d = Ecto.create TestModel[id: 3000, version: 1]
    assert Ecto.destroy d
  end

  test :get do
    model = Ecto.save TestModel[id: 100, version: 10]
    assert model == Ecto.get TestModel, 100
    assert nil == Ecto.get TestModel, 666
    assert_raise Ecto.RecordNotFound, fn ->
      Ecto.get! TestModel, 666
    end
  end

  test :all do
    models = [ TestModel[id: 100, version: 100],
               TestModel[id: 101, version: 100],
               TestModel[id: 102, version: 100] ]
    
    Enum.each models, Ecto.save &1

    assert models == Ecto.all TestModel, where: [ version: 100 ], order_by: :id

    { models, _ } = Enum.split models, 2
    assert models == Ecto.all TestModel, where: [ version: 100 ], order_by: :id, limit: 2
  end

  test :allocate do
    assert TestModel[id: 1, version: 2] == TestModel.__ecto__(:allocate, {1,2})
  end

  test :fields do
    [:id, :version] = TestModel.__ecto__(:fields)
  end
end