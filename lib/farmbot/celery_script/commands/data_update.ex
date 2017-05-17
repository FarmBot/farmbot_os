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

  @doc ~s"""
    SyncInvalidate
    args: %{value: String.t},
    body: [Pair.t]
  """
  @spec run(%{value: String.t}, [Pair.t], Ast.context) :: Ast.context
  def run(%{value: verb}, pairs, context) do
    verb = parse_verb_str(verb)
    Enum.each(pairs, fn(%{args: %{label: s, value: nowc}}) ->
      syncable = s |> parse_syncable_str()
      value = nowc |> parse_val_str()
      :ok = Database.set_awaiting(context.database, syncable, verb, value)
    end)
    context
  end

  @type number_or_wildcard :: non_neg_integer | binary # "*"
  @type syncable ::  Farmbot.Database.syncable

  @spec parse_syncable_str(binary) :: syncable
  defp parse_syncable_str(str) do
    Module.concat([Farmbot.Database.Syncable, Macro.camelize(str)])
  end

  @spec parse_val_str(binary) :: number_or_wildcard
  defp parse_val_str("*"), do: "*"
  defp parse_val_str(int) when is_integer(int), do: int
  defp parse_val_str(number), do: String.to_integer(number)

  @spec parse_verb_str(binary) :: verb
  defp parse_verb_str("add"), do: :add
  defp parse_verb_str("remove"), do: :remove
  defp parse_verb_str("update"), do: :update
end
