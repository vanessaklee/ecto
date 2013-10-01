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
      @before_compile { unquote(__MODULE__), :__ecto__ }
      @before_compile { unquote(__MODULE__), :__record__ }

      @ecto_primary_key :id

      Enum.each [:record_fields, :ecto_validations, :ecto_skip_on_update],
        Module.register_attribute(__MODULE__, &1, accumulate: true, persist: false)

      import Ecto.Model
    end
  end

  defmacro table_name(name) do
    quote do
      @ecto_table unquote(name)
    end
  end

  defmacro primary_key(name, opts // []) do
    default = opts[:default]
    quote do
      @ecto_primary_key unquote(name)
      @record_fields { unquote(name), unquote(default) }
    end
  end

  defmacro field(name, opts // []) do
    default = opts[:default]
    validator = opts[:validator]
    updatable = Keyword.get opts, :updatable, true
    quoted_validator = quote do: unquote(validator)
    quote do
      @record_fields { unquote(name), unquote(default) }
      if unquote(validator) do
        @ecto_validations { unquote(name), unquote(Macro.escape(quoted_validator)) }
      end
      if not unquote(updatable) do
        @ecto_skip_on_update unquote(name)
      end
    end
  end

  defmacro __record__(_) do
    fields = Module.get_attribute(__CALLER__.module, :record_fields)
    Record.deffunctions(fields, __CALLER__)
    Record.deftypes(fields, [], __CALLER__)
    :ok
  end

  defmacro __ecto__(_) do
    table          = Module.get_attribute(__CALLER__.module, :ecto_table) |> to_string
    primary_key    = Module.get_attribute(__CALLER__.module, :ecto_primary_key)
    validations    = Module.get_attribute(__CALLER__.module, :ecto_validations)
    skip_on_update = Module.get_attribute(__CALLER__.module, :ecto_skip_on_update)

    fields = Module.get_attribute(__CALLER__.module, :record_fields)
    fields = Enum.map fields, elem(&1, 0)

    allocate_fields = lc key inlist fields do
      { key, quote do: __allocate__(var!(args), unquote(to_string(key))) }
    end

    { allocate_fields2, _ } = Enum.reduce fields, { [], 0 }, fn
      (key, { acc, pos }) ->
        acc = [ { key, quote do: elem( var!(args), unquote(pos)) } | acc ]
        pos = pos + 1
        { acc, pos }
    end

    quote location: :keep do
      # TODO: This should be part of Record itself.
      defp __allocate__(list, key) do
        case :lists.keyfind(key, 1, list) do
          { ^key, value } -> value
          false -> nil
        end
      end

      def __ecto__(:allocate, var!(args)) when is_list(var!(args)) do
        __MODULE__[unquote(allocate_fields)]
      end

      def __ecto__(:allocate, var!(args)) when is_tuple(var!(args)) do
        __MODULE__[unquote(allocate_fields2)]
      end

      def __ecto__(key, _record),    do: __ecto__(key)
      def __ecto__(:table),          do: unquote(table)
      def __ecto__(:primary_key),    do: unquote(primary_key)
      def __ecto__(:fields),         do: unquote(fields)
      def __ecto__(:validations),    do: unquote(validations)
      def __ecto__(:skip_on_update), do: unquote(skip_on_update)
    end
  end
end
