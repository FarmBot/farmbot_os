defmodule FarmbotOS.Lua.Util do
  @doc "Convert an Elixir map to a Lua table"
  def map_to_table(map) do
    Enum.map(map, fn
      {key, %{} = value} ->
        {to_string(key), map_to_table(value)}

      {key, value} ->
        {to_string(key), value}
    end)
  end
end
