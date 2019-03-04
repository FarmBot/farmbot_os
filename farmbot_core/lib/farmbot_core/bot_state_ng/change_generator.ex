defmodule Farmbot.BotStateNG.ChangeGenerator do
  @moduledoc """
  Takes a map and returns instructions on how to construct that data.
  """

  @doc "Returns a list of changes that have been applied to a map."
  def changes(changes, path \\ [], acc \\ [])

  def changes(%Ecto.Changeset{changes: changes}, path, acc) do
    changes(changes, path, acc)
  end

  def changes(%_{} = changes, path, acc) do
    Map.from_struct(changes)
    |> changes(path, acc)
  end

  def changes(%{} = changes, path, acc) do
    Map.to_list(changes)
    |> changes(path, acc)
  end

  def changes([{key, change} | rest], path, acc) do
    cond do
      is_number(change) ->
        changes(rest, path, [{add_paths(path, key), change} | acc])

      is_binary(change) ->
        changes(rest, path, [{add_paths(path, key), change} | acc])

      is_nil(change) ->
        changes(rest, path, [{add_paths(path, key), change} | acc])

      is_boolean(change) ->
        changes(rest, path, [{add_paths(path, key), change} | acc])

      is_map(change) ->
        acc = changes(change, add_paths(path, key), acc)
        changes(rest, path, acc)

      is_list(change) ->
        raise("no lists")

      true ->
        raise("unknown data: #{inspect(change)}")
    end
  end

  def changes([], _path, acc), do: acc

  defp add_paths(left, right) do
    ensure_list(left) ++ ensure_list(right)
  end

  defp ensure_list(value) when is_list(value), do: value
  defp ensure_list(value), do: [value]
end
