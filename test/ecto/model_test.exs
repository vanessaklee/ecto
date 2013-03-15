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
    Ecto.Pool.equery %b;
      CREATE TABLE ecto_test ( id serial primary key, version int );
    :ok
  end

  teardown_all do
    Ecto.Pool.equery "drop table ecto_test"
    :ok
  end

  def model, do: TestModel[id: 1, version: 1]

  test :create do
    assert model == Ecto.save model
  end

  test "cannot create with existing id" do
    model = TestModel[id: 22, version: 1]
    Ecto.create model
    assert_raise RuntimeError, fn ->
      Ecto.create model
    end
  end

  test :update do
    version2 = model.version 2
    assert version2 == Ecto.save(version2)
  end

  test :destroy do
    d = Ecto.create TestModel[id: 2, version: 1]
    assert 1 == Ecto.destroy d
  end

  test :get do
    assert model == Ecto.get TestModel, 1
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
end