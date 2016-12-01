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
  defmacro __using__(
    name: name, model: model)
  do
    quote do
      @moduledoc """
        A Farmbot Syncable #{unquote name}
      """
      @enforce_keys unquote(model)
      @type t :: %unquote(name){}
      defstruct @enforce_keys

      @doc """
        Creates a #{unquote(name)} Object.
        returns {:ok, %#{unquote(name)}} or {#{unquote(name)}, :malformed}
      """
      @spec create({:ok, map} | map) :: {:ok, t} | {unquote(name), :malformed}
      def create({:ok, map}), do: create(map)
      def create( unquote( create_json_map(model) ) ),
        do: {:ok, unquote( create_struct(name, model) )}

      def create(unquote( create_keyed_map(model) ) ),
        do: {:ok, unquote( create_struct(name, model) )}

      def create( map ) when is_map(map),
        do: {unquote(name), {:missing_keys, model -- (map |> Map.keys)}}

      def create(_), do: {unquote(name), :malformed}

      @doc """
        Same as create\1 but raises an exception if it fails.
      """
      @spec create!({:ok, map} | map) :: t
      def create!({:ok, thing}), do: create!(thing)
      def create!(thing) do
        case create(thing) do
          {:ok, success} -> success
          {unquote(name), reason} -> error(unquote(name), reason)
        end
      end

      defp error(name, reason) do
        raise "#{name} #{inspect reason} expecting: #{inspect model}}"
      end

      @doc """
        Lists all the keys available for creating a #{unquote(name)}
      """
      @spec model :: [atom]
      def model, do: @enforce_keys
    end
  end

  @spec create_json_map([atom]) :: term
  defp create_json_map(model) when is_list(model) do
    # [:a, :b, :c] should return %{"a" => a, "b" => b, "c" => c}
    f = Enum.reduce(model, [], fn(key), acc ->
      var_key = String.trim("#{inspect Atom.to_string(key)}", "\"")
      [{
        Atom.to_string(key),
        Code.string_to_quoted!(var_key)
      }] ++ acc
    end)
    {:%{}, [], f}
  end

  @spec create_keyed_map([atom]) :: {:%{}, [], [term]}
  defp create_keyed_map(model) when is_list(model) do
    # [:a, :b, :c] should return %{a: a, b: b, c: c}
    f = Enum.reduce(model, [], fn(key), acc ->
      var_key = String.trim("#{inspect Atom.to_string(key)}", "\"")
      [{
        key,
        Code.string_to_quoted!(var_key)
      }] ++ acc
    end)
    {:%{}, [], f}
  end

  @spec create_struct(term,[atom]) :: term
  defp create_struct(name, model) when is_list(model) do
    # [:a, :b, :c] should return %{a: a, b: b, c: c}
    f = Enum.reduce(model, [], fn(key, acc) ->
      var_key = String.trim("#{inspect Atom.to_string(key)}", "\"")
      [{
        key,
        Code.string_to_quoted!(var_key)
      }] ++ acc
    end)
    {:%, [], [{:__aliases__, [], [name]}, {:%{}, [], f}]}
  end
end
