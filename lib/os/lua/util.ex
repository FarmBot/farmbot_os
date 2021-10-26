defmodule FarmbotOS.Lua.Util do
  @doc "Convert an Elixir map to a Lua table"
  def map_to_table(map) when is_map(map) do
    Enum.map(map, fn
      {key, %DateTime{} = dt} -> {to_string(key), to_string(dt)}
      {key, %{} = value} -> {to_string(key), map_to_table(value)}
      {key, value} -> {to_string(key), value}
    end)
  end

  def map_to_table(list) when is_list(list) do
    list
    |> Enum.with_index()
    |> Enum.map(fn {val, inx} -> {inx + 1, val} end)
    |> Map.new()
  end

  def map_to_table(other), do: other

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
    keys = Map.keys(acc)
    not_array? = Enum.find_value(keys, fn key -> !is_number(key) end)
    not_populated? = Enum.count(keys) == 0

    if not_array? || not_populated? do
      acc
    else
      Map.values(acc)
    end
  end
end
