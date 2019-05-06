defmodule FarmbotCore.BotStateNG.DeleteGenerator do
  @moduledoc """
  Generates a list of lists of keys that were deleted
  from a map.
  """

  def deletes(initial, next, path \\ [], acc \\ [])

  def deletes(%{} = initial, %{} = next, path, acc) do
    deletes(Map.to_list(initial), Map.to_list(next), path, acc)
  end

  def deletes([{key, val} | rest], next, path, acc) do
    cond do
      is_number(val) ->
        do_deletes(key, {next, next}, rest, path, acc)

      is_binary(val) ->
        do_deletes(key, {next, next}, rest, path, acc)

      is_nil(val) ->
        do_deletes(key, {next, next}, rest, path, acc)

      is_boolean(val) ->
        do_deletes(key, {next, next}, rest, path, acc)

      is_map(val) ->
        deletes(rest, next, path, acc)

      is_list(val) ->
        raise("no lists")

      true ->
        raise("unknown data: #{inspect(val)}")
    end
  end

  def deletes([], _next, _path, acc), do: acc

  # If the key exists in both maps, exit this loop. It was not deleted.
  def do_deletes(key, {[{key, _} | _next_rest], next}, rest, path, acc) do
    deletes(rest, next, path, acc)
  end

  # If the key does not match, move on to the next key
  def do_deletes(key, {[{_not_the_same_key, _val} | next_rest], next}, rest, path, acc) do
    do_deletes(key, {next_rest, next}, rest, path, acc)
  end

  # If we enumerated the entire list of `next` map keys,
  # this key must have been deleted.
  def do_deletes(key, {[], next}, rest, path, acc) do
    deletes(rest, next, path, [add_paths(path, key) | acc])
  end

  defp add_paths(left, right) do
    ensure_list(left) ++ ensure_list(right)
  end

  defp ensure_list(value) when is_list(value), do: value
  defp ensure_list(value), do: [value]

end
