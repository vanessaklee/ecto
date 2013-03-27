Code.require_file "../../test_helper.exs", __FILE__

alias Validatex, as: V

defmodule TestModel do
  use Ecto.Model
  table_name :ecto_test
  primary_key :id
  field :version

  def new?(TestModel[version: 1] = m), do: "yup... #{m.id} is new"
end

defmodule WithDefaults do
  use Ecto.Model
  primary_key :id, default: 0
  field :version, default: 0
end

defmodule WithValidations do
  use Ecto.Model
  table_name :ecto_test
  primary_key :id
  field :name, validator: V.Type.new(is: :string)
end

defmodule WithUpdatable do
  use Ecto.Model
  table_name :ecto_test
  primary_key :id
  field :version
  field :name, updatable: false
  field :comment
end

defmodule EctoModelTest do
  use ExUnit.Case

  setup_all do
    Ecto.Pool.start_link
    Ecto.Pool.query %b;
      CREATE TABLE ecto_test (id SERIAL PRIMARY KEY, version INT, name TEXT, comment TEXT);
    :ok
  end

  setup do
    Ecto.Pool.query "DELETE FROM ecto_test *"
    :ok
  end

  teardown_all do
    Ecto.Pool.query "DROP TABLE ecto_test"
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
    version3 = model.version nil
    assert version3 == Ecto.save(version3)
    assert version3 == Ecto.get TestModel, model.id
  end

  test :destroy do
    d = Ecto.create TestModel[id: 3000, version: 1]
    assert Ecto.destroy d
  end

  test :destroy_where do
    version = 9999999
    Enum.each [1,2,3], fn(_) -> Ecto.create TestModel[ version: version ] end
    assert 3 == Enum.count Ecto.all(TestModel, where: [ version: version ])
    Ecto.destroy TestModel, where: [ version: version ]
    assert 0 == Enum.count Ecto.all(TestModel, where: [ version: version ])
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

  test :match_in_def_fun do
    assert "yup... 2 is new" == TestModel.new? TestModel[id: 2, version: 1]
  end

  test :field_defaults do
    assert WithDefaults[id: 0, version: 0] == WithDefaults.new
  end

  test :validations do
    model = WithValidations[id: 1, name: 31337]

    assert not Ecto.valid?(model)

    assert_raise Ecto.RecordInvalid, fn ->
      Ecto.save! model
    end
  end

  test :updatable do
    model = WithUpdatable[id: 1, version: 1, name: "NAME", comment: "CHANGE ME!"]
    model = Ecto.create model
    model = model.version 2
    model = model.name "NEW NAME"
    model = model.comment "CHANGED!"
    assert WithUpdatable[id: 1, version: 2, name: "NAME", comment: "CHANGED!"] = Ecto.save model
  end

  test :null_to_nil do
    model = WithUpdatable[id: 1, version: 1]
    # no nulls at save
    assert model == Ecto.save model
    model2 = model.version 2
    # no nulls at update
    assert model2 == Ecto.save model2
    assert [model] == Ecto.all WithUpdatable, where: [ id: 1 ]
  end
end
