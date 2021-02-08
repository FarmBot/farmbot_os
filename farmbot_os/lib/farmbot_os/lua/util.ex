defmodule FarmbotOS.Lua.Util do
  @doc "Convert an Elixir map to a Lua table"
  def map_to_table(map) do
    Enum.map(map, fn
      {key, %DateTime{} = dt} -> {to_string(key), to_string(dt)}
      {key, %{} = value} -> {to_string(key), map_to_table(value)}
      {key, value} -> {to_string(key), value}
    end)
  end

  def lua_to_elixir(table) when is_list(table) do
    table_to_map(table, %{})
  end

  def lua_to_elixir(f) when is_function(f), do: "[Lua Function]"

  def lua_to_elixir(other), do: other

  def table_to_map([{key, value} | rest], acc) do
    next = Map.merge(acc, %{key => lua_to_elixir(value)})
    table_to_map(rest, next)
  end

  def table_to_map([], acc) do
    # POST PROCESSING
    not_array? =
      acc
      |> Map.keys()
      |> Enum.find_value(fn key -> !is_number(key) end)

    if not_array? do
      acc
    else
      Map.values(acc)
    end
  end
end
