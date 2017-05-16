defmodule Farmbot.CeleryScript.Command.DataUpdate do
  @moduledoc """
    SyncInvalidate
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.Database
  require Logger
  @behaviour Command

  @typedoc """
    The verb from DataUpdate:
    https://github.com/FarmBot/farmbot-js/blob/master/src/corpus.ts#L611
  """
  @type verb :: :add | :remove | :update
  require IEx

  @doc ~s"""
    SyncInvalidate
    args: %{value: String.t},
    body: [Pair.t]
  """
  @spec run(%{value: String.t}, [Pair.t]) :: no_return
  def run(%{value: verb}, pairs) do
    verb = parse_verb_str(verb)
    Enum.each(pairs, fn(%{args: %{label: s, value: nowc}}) ->
      syncable = s |> parse_syncable_str()
      value = nowc |> parse_val_str()
      Database.set_outdated(syncable, verb, value)
    end)
  end

  @type number_or_wildcard :: non_neg_integer | binary # "*"
  @type syncable :: :sequence | :regimen | :farm_event | :point
  #FIXME ^

  @spec parse_syncable_str(binary) :: syncable
  defp parse_syncable_str(str), do: String.to_atom(str)

  @spec parse_val_str(binary) :: number_or_wildcard
  defp parse_val_str("*"), do: "*"
  defp parse_val_str(int) when is_integer(int), do: int
  defp parse_val_str(number), do: String.to_integer(number)

  @spec parse_verb_str(binary) :: verb
  defp parse_verb_str("add"), do: :add
  defp parse_verb_str("remove"), do: :remove
  defp parse_verb_str("update"), do: :update
end
