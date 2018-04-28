defmodule Farmbot.Repo.Snapshot do
  @moduledoc false
  alias Farmbot.Repo.Snapshot

  defmodule Diff do
    @moduledoc false
    defstruct [
      additions: [],
      deletions: [],
      updates: [],
    ]
  end

  defstruct [data: [], hash: nil]

  def diff(%Snapshot{} = old, %Snapshot{} = new) do
    struct(Diff, [
      additions:       calculate_additions(old.data, new.data),
      deletions:       calculate_deletions(old.data, new.data),
      updates:         calculate_updates(old.data, new.data)
    ])
  end

  def diff(%Snapshot{} = data) do
    struct(Diff, [
      additions: calculate_additions([], data.data),
      deletions: calculate_deletions([], data.data),
      updates:   []
    ])
  end

  defp calculate_additions(old, new) do
    Enum.reduce(new, [], fn(new_object, acc) ->
      maybe_old_object = Enum.find(old, fn(old_object) ->
        is_correct_mod? = old_object.__struct__ == new_object.__struct__
        is_correct_id? = old_object.id == new_object.id
        is_correct_mod? && is_correct_id?
      end)
      if maybe_old_object do
        acc
      else
        [new_object | acc]
      end
    end)
  end

  # We need all the items that are not in `new`, but were in `old`
  defp calculate_deletions(old, new) do
    Enum.reduce(old, [], fn(old_object, acc) ->
      maybe_new_object = Enum.find(new, fn(new_object) ->
        is_correct_mod? = old_object.__struct__ == new_object.__struct__
        is_correct_id? = old_object.id == new_object.id
        is_correct_mod? && is_correct_id?
      end)

      if maybe_new_object do
        acc
      else
        [old_object | acc]
      end
    end)
  end

  # We need all items that weren't added, or deleted.
  defp calculate_updates(old, new) do
    index = fn(%{__struct__: mod, id: id} = data) ->
      {{mod, id}, data}
    end

    old_index = Map.new(old, index)
    new_index = Map.new(new, index)
    a = Map.take(new_index, Map.keys(old_index))
    Enum.reduce(a, [], fn({key, val}, acc) ->
      if old_index[key] != val do
        [val | acc]
      else
        acc
      end
    end)
  end

  def md5(%Snapshot{data: data} = snapshot) do
    data
    |> Enum.map(&:crypto.hash(:md5, inspect(&1)))
    |> fn(data) ->
      :crypto.hash(:md5, data) |> Base.encode16()
    end.()
    |> fn(hash) ->
      %{snapshot | hash: hash}
    end.()
  end

  defimpl Inspect, for: Snapshot do
    def inspect(%Snapshot{data: []}, _) do
      "#Snapshot<[NULL]>"
    end

    def inspect(%Snapshot{hash: hash}, _) when is_binary(hash) do
      "#Snapshot<#{hash}>"
    end
  end
end
