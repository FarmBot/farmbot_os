defmodule Syncable do
  @moduledoc """
    Creates a syncable object from Farmbot's rest api.
    Example:
      iex> defmodule BubbleGum do
      ...>    use Syncable, name: __MODULE__, model: [:flavors, :brands]
      ...> end
      iex> BubbleGum.create!(%{"flavors" => ["mint", "berry"], "brands" => ["BigRed"]})
           {:ok, %BubbleGum{flavors: ["mint", "berry"], brands:  ["BigRed"]}}
  """
  defmacro __using__(name: name, model: model) do
    # This is an ast that evaluates essentially to:
    # "a" => a,
    # "b" => b
    json_map_args =
    Enum.map(model, fn(k) ->
      key = inspect(k)
       <<":", rkey :: binary>> = key
      {rkey, {:var!, [], [{k, [], nil}]}}
    end)

    # This is an ast for building a map. it evaluates to:
    # %{"a" => a, "b" => b}
    json_map = {:%{}, [], json_map_args}

    # Another AST body.
    # milk: 1, eggs: 2
    fb =
    Enum.map(model, fn(k) ->
      val = quote do mutate(unquote(k), unquote({k, [], nil}) ) end
      {k, val}
    end)
    # This equates basically to:
    # %Fridge{milk: 1, eggs: 2}
    module_struct = {:%, [], [{:__aliases__, [], [name]}, {:%{}, [], fb}]}
    quote do
      import Syncable
      @moduledoc """
        A Farmbot Syncable #{unquote name}
      """
      @enforce_keys unquote(model)
      @type t :: %unquote(name){}
      defstruct @enforce_keys

      @doc """
        A Farmbot Syncable #{unquote name}
        Will either return:
        {:ok, #{unquote name}}  or
        {#{unquote name}, reason}
      """
      @spec create({:ok, map} | map) :: {:ok, t} | {unquote(name), atom}
      def create(unquote(json_map)), do: {:ok, unquote(module_struct)}
      def create({:ok, t}), do: create(t)
      def create(map) when is_map(map) do
        missing = model -- Map.keys(map)
        {unquote(name), {:missing_keys, missing}}
      end
      def create(_), do: {unquote(name), :malformed}

      @doc """
        Same as create\1 except it returns successfully or raises an runtime exception.
      """
      @spec create!({:ok, map} | map) :: t
      def create!(t) do
        case create(t) do
          {:ok, thing} ->
            thing
          {unquote(name), reason} ->
            raise("#{inspect(unquote(name))} #{inspect(reason)} expecting: #{inspect model}")
        end
      end

      @doc """
        The required keys to build a #{unquote(name)} object.
      """
      @spec model :: [atom]
      def model, do: @enforce_keys

      # This ties into that transform macro.
      @spec mutate(atom, any) :: any
      defp mutate(_k, v), do: v
      defoverridable [mutate: 2]
    end
  end

  @doc """
    Transforms the state before it is entered into the struct.
    Basically you call transform(key) do something end where something will be
    the new value for key.
    Example:
      Iex> defmodule Dog do
      ...>  use Syncable, name: __MODULE__, model: [:legs]
      ...>  transform :legs do
      ...>    new_thing = before + 1
      ...>    IO.puts "This probably isnt a dog anymore?"
      ...>    new_thing
      ...>  end
      ...> end
      Iex> Dog.create!("legs" => 4)
           This probably isnt a dog anymore?
           %Dog{legs: 5}
  """
  defmacro transform(key, block) do
    quote do
      defp mutate(unquote(key), var!(before)), unquote block
      defp mutate(_k, v), do: v
    end
  end
end
