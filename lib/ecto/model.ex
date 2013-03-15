defmodule Ecto.Model do
  @moduledoc """
  Model wrapper.

  ## Examples

  defmodule User do
    use Ecto.Model

    @todo "Uniqueness validation"

    def create_sample!(name, email) do
      { :ok, salt } = :bcrypt.gen_salt() 
      { :ok, hash } = :bcrypt.hashpw("123456", salt)
      Ecto.create User.new(name: name, email: email, encrypted_password: list_to_binary(hash))
    end

    table_name "users"
    field :name
    field :email
    field :encrypted_password
    field :created_at
    field :updated_at

    def as_json(user) do
      [ id: user.id,
        name: user.name,
        email: user.email ]
    end
  end
  """

  defmacro __using__(_) do
    quote do
      @before_compile { unquote(__MODULE__), :__record__ }
      @before_compile { unquote(__MODULE__), :__ecto__ }

      @ecto_primary_key :id

      Enum.each [:ecto_fields],
        Module.register_attribute(__MODULE__, &1, accumulate: true, persist: false)

      import Ecto.Model
    end
  end

  defmacro table_name(name) do
    quote do
      @ecto_table unquote(name)
    end
  end

  defmacro primary_key(name) do
    quote do
      @ecto_primary_key unquote(name)
      @ecto_fields unquote(name)
    end
  end

  defmacro field(name) do
    quote do
      @ecto_fields unquote(name)
    end
  end

  defmacro __record__(_) do
    fields = Module.get_attribute(__CALLER__.module, :ecto_fields)
    fields = Enum.reverse(fields)

    Record.deffunctions(fields, __CALLER__)
    Record.deftypes(fields, [], __CALLER__)
    :ok
  end

  defmacro __ecto__(_) do
    table       = Module.get_attribute(__CALLER__.module, :ecto_table) |> to_binary
    primary_key = Module.get_attribute(__CALLER__.module, :ecto_primary_key)

    fields = Module.get_attribute(__CALLER__.module, :ecto_fields)
    fields = Enum.reverse(fields)
    fields = lc key inlist fields do
      { key, quote do: __allocate__(var!(args), unquote(to_binary(key))) }
    end

    quote location: :keep do
      # TODO: This should be part of Record itself.
      defp __allocate__(list, key) do
        case :lists.keyfind(key, 1, list) do
          { ^key, value } -> value
          false -> nil
        end
      end

      def __ecto__(:allocate, var!(args)) do
        __MODULE__[unquote(fields)]
      end

      def __ecto__(key, _record), do: __ecto__(key)
      def __ecto__(:table),       do: unquote(table)
      def __ecto__(:primary_key), do: unquote(primary_key)
    end
  end
end
