defmodule Syncable do

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

  defmacro __using__(
    name: name, model: model)
  do
    quote do
      @moduledoc """
        A Farmbot Syncable #{unquote name}
      """
      @enforce_keys unquote(model)
      defstruct @enforce_keys

      @type t :: %unquote(name){}

      @doc """
        Creates a #{unquote(name)} Object.
        returns {:ok, %#{unquote(name)}} or {#{unquote(name)}, :malformed}
      """
      @spec create(map) :: {:ok, t} | {unquote(name), :malformed}
      def create( unquote( create_json_map(model) ) ),
        do: {:ok, unquote( create_struct(name, model) )}

      def create(unquote( create_keyed_map(model) ) ),
        do: {:ok, unquote( create_struct(name, model) )}

      def create( fail ) when is_map(fail),
        do: {unquote(name), :missing_keys, model -- (fail |> Map.keys)}

      def create(_), do: {unquote(name), :malformed}

      @doc """
        Same as create\1 but raises an exception if it fails.
      """
      @spec create!(map) :: t
      def create!(thing) do
        case create(thing) do
          {:ok, success} ->
            success
          {unquote(name), :missing_keys, list} ->
            raise "#{unquote(name)} missing keys! expecting: #{inspect model} but got: #{inspect Map.keys(thing)}"
          {unquote(name), :malformed} ->
            raise "Malformed #{unquote(name)}. expecting: #{inspect model}"
        end
      end

      @doc """
        Lists all the keys available for creating a #{unquote(name)}
      """
      @spec model :: [atom]
      def model, do: @enforce_keys
    end
  end
end
