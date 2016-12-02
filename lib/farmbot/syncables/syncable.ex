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
      generate(unquote(name), unquote(model))
      def create({:ok, t}), do: create(t)
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
      defp mutate(_k, v), do: {:ok, v}
      defp validate({:ok, thing}, _key), do: thing
      defp validate(error, key), do: throw {:bad_validate, {key, error}}
      defoverridable [mutate: 2, validate: 2]
    end
  end

  defmacro generate(name, model) do
    quote bind_quoted: [name: name, model: model] do

      def create(map) when is_map(map) do
        try do



          # creates a map with atom keys rather than strings
          m = Map.new(map, fn({key, v}) ->
            thing = String.to_atom(key)
            value = mutate(thing, v) |> validate(key)
            {thing, value}
          end)
          
          # THIS MAP MAY HAVE EXTRA STUFF ON IT NEED TO FIND A WAY TO
          # GET RID OF THEM BEFORE RETURNING
          g = struct!(unquote(name), m)
          {:ok, g}
        rescue
          module in FunctionClauseError ->
            "didnt mutate #{inspect module}"
        catch
          error -> parse_error(error)
        end
      end
      defp parse_error({unquote(name), error}), do: {unquote(name), error}
      defp parse_error(error), do: {unquote(name), error}
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
  defmacro mutation(key, block) do
    quote do
      defp mutate(unquote(key), var!(before)), unquote(block)
    end
  end
end
