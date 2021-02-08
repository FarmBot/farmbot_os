defmodule FarmbotOS.Lua.Util do
  @doc "Convert an Elixir map to a Lua table"
  def map_to_table(map) do
    Enum.map(map, fn
      {key, %DateTime{} = dt} -> {to_string(key), to_string(dt)}
      {key, %{} = value} -> {to_string(key), map_to_table(value)}
      {key, value} -> {to_string(key), value}
    end)
  end

  # def table_to_map([{key, value} | rest], acc \\ %{}) do
  # end

  # def table_to_map([], acc \\ %{}) do
  # end
end
