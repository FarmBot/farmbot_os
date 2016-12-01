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
    fa =
    Enum.map(model, fn(k) ->
      key = inspect(k)
       <<":", rkey :: binary>> = key
      {rkey, {:var!, [], [{k, [], nil}]}}
    end)

    fb =
    Enum.map(model, fn(k) ->
      # val = {k, [], nil}
      # val = thing(k, {k, [], nil})
      val = quote do mutate(unquote(k), unquote({k, [], nil}) ) end
      {k, val}
    end)

    a = {:%{}, [], fa}
    b = {:%, [], [{:__aliases__, [], [name]}, {:%{}, [], fb}]}

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
      """
      def create(unquote(a)), do: {:ok, unquote(b)}
      def create({:ok, t}), do: create(t)
      def create(map) when is_map(map) do
        missing = model -- Map.keys(map)
        {unquote(name), {:missing_keys, missing}}
      end
      def create(_), do: {unquote(name), :malformed}

      def create!(t) do
        case create(t) do
          {:ok, thing} -> thing
          {unquote(name), reason} -> raise("#{inspect(unquote(name))} #{inspect(reason)} expecting: #{inspect model}")
        end
      end

      def model, do: @enforce_keys
      defp mutate(_k, v), do: v
      defoverridable [mutate: 2]
    end
  end

  defmacro transform(key, block) do
    quote do
      defp mutate(unquote(key), var!(before)), unquote block
      defp mutate(_k, v), do: v
    end
  end
end
