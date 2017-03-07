defmodule Redis.Client.Public do
  @doc """
    Sends a command to redis. Blocks
  """
  @spec send_redis(pid, [binary]) :: binary
  def send_redis(conn, stuff), do: Redix.command!(conn, stuff)

  @doc """
    Input a value by a given key.
  """
  @spec input_value(pid, String.t, any) :: [String.t]
  def input_value(redis, key, value) when is_map(value) do
    input_map(redis, %{key => value})
  end

  def input_value(redis, key, value) when is_list(value) do
    input_list(redis, key, value)
  end

  def input_value(redis, key, value) when is_tuple(value) do
    input_value(redis, key, Tuple.to_list(value))
  end

  def input_value(redis, key, value),
    do: send_redis redis, ["SET", key, value]

  defp input_list(redis, key, list) do
    send_redis redis, ["DEL", key]
    for i <- list do
      if is_binary(i) or is_integer(i) do
        send_redis redis, ["RPUSH", key, i]
      end
    end
  end

  @spec input_map(pid, map | struct, String.t | nil) :: [String.t]
  defp input_map(redis, map, bloop \\ nil)
  defp input_map(redis, %{__struct__: _} = map, bloop),
    do: input_map(redis, map |> Map.from_struct, bloop)

  @lint false
  defp input_map(redis, map, bloop) when is_map(map) do
    Enum.map(map, fn({key, value}) ->
      cond do
        is_map(value) ->
          if bloop do
            input_map(redis, value, "#{bloop}.#{key}")
          else
            input_map(redis, value, key)
          end

        is_list(value) ->
          if bloop do
            input_list(redis, "#{bloop}.#{key}", value)
          else
            input_list(redis, key, value)
          end

        true ->
          if bloop do
            input_value(redis, "#{bloop}.#{key}", value)
          else
            input_value(redis, key, value)
          end
      end
    end)
    |> List.flatten
  end
end
