defmodule Farmbot.CeleryScript.Command.DataUpdate do
  @moduledoc """
    SyncInvalidate
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.Sync.Cache
  require Logger
  @behaviour Command

  @doc ~s"""
    SyncInvalidate
    args: %{value: String.t},
    body: [Pair.t]
  """
  @spec run(%{value: String.t}, [Pair.t]) :: no_return
  def run(%{value: verb}, pairs) do
    pairs |> parse_pairs |> Cache.add(parse_verb_str(verb))
  end

  @type number_or_wildcard :: non_neg_integer | binary # "*"
  @type sync_cache_map :: %{syncable: syncable, value: number_or_wildcard}
  @type syncable :: :sequence | :regimen | :farm_event | :point
  @type verb :: :updated | :deleted

  @spec parse_pairs([Pair.t], [sync_cache_map]) :: [sync_cache_map]
  defp parse_pairs(pairs, acc \\ [])
  defp parse_pairs([], acc), do: acc
  defp parse_pairs([%{args: %{label: s, value: nowc}} | rest], acc) do
    syncable = s |> parse_syncable_str()
    value = nowc |> parse_val_str()
    item = %{syncable: syncable, value: value}
    parse_pairs(rest, [item | acc])
  end

  @spec parse_syncable_str(binary) :: syncable
  defp parse_syncable_str(str), do: String.to_atom(str)

  @spec parse_val_str(binary) :: number_or_wildcard
  defp parse_val_str("*"), do: "*"
  defp parse_val_str(number), do: String.to_integer(number)

  @spec parse_verb_str(binary) :: verb
  defp parse_verb_str("updated"), do: :updated
  defp parse_verb_str("deleted"), do: :deleted
end
