defmodule Farmbot.Repo.Snapshot do
  @moduledoc false
  alias Farmbot.Repo.Snapshot

  defmodule Diff do
    @moduledoc false
    defstruct [
      additions: [],
      deletions: [],
      updates: []
    ]
  end

  defstruct [data: []]

  def diff(%Snapshot{} = old, %Snapshot{} = new) do
    struct(Diff, [
      additions: calculate_additions(old.data, new.data),
      deletions: calculate_deletions(old.data, new.data),
      updates:   calculate_updates(old.data, new.data)
    ])
  end

  defp calculate_additions(old, new) do
    Enum.reject(new, fn(data) ->
      Enum.find(old, fn(%{id: id, __struct__: mod}) -> (mod == data.__struct__ && id == data.id) end)
    end)
  end

  defp calculate_deletions(old, new) do
    Enum.reject(old, fn(data) ->
      data in old
    end)
  end

  defp calculate_updates(old, new) do
    Enum.reject(old, fn(data) ->
      object = Enum.find(new, fn(%{id: id, __struct__: mod}) -> (mod == data.__struct__ && id == data.id) end)
      object == data
    end)
  end

  def md5(%Snapshot{data: data}) do
    data
    |> Enum.map(&:crypto.hash(:md5, inspect(&1)))
    |> fn(data) ->
      :crypto.hash(:md5, data) |> Base.encode16()
    end.()
  end

  defimpl Inspect, for: Snapshot do
    def inspect(%Snapshot{} = snapshot, _) do
      "#Snapshot<#{Snapshot.md5(snapshot)}>"
    end
  end
end
