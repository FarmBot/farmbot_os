defmodule Farmbot.CeleryScript.Command.DataUpdate do
  @moduledoc """
    SyncInvalidate
  """

  alias Farmbot.CeleryScript.{Command, Types}
  alias Farmbot.Database
  alias Database.Syncable.{
    Device,
    FarmEvent,
    Peripheral,
    Point,
    Regimen,
    Sequence,
    Tool
  }
  use Farmbot.DebugLog
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
  @spec run(%{value: binary}, Types.pairs, Context.t) :: Context.t
  def run(%{value: verb}, pairs, context) do
    verb = parse_verb_str(verb)
    Enum.each(pairs, fn(%{args: %{label: s, value: nowc}}) ->
      syncable = s |> parse_syncable_str()
      if syncable do
        value = nowc |> parse_val_str()
        :ok = Database.set_awaiting(context, syncable, verb, value)
      else
        raise Farmbot.CeleryScript.Error, context: context,
          message: "Could not translate syncable: #{s}"
      end
    end)
    context
  end

  @type number_or_wildcard :: non_neg_integer | binary # "*"
  @type syncable ::  Farmbot.Database.syncable | nil

  @spec parse_syncable_str(binary) :: syncable
  defp parse_syncable_str("regimens"),    do: Regimen
  defp parse_syncable_str("peripherals"), do: Peripheral
  defp parse_syncable_str("sequences"),   do: Sequence
  defp parse_syncable_str("farm_events"), do: FarmEvent
  defp parse_syncable_str("tools"),       do: Tool
  defp parse_syncable_str("points"),      do: Point
  defp parse_syncable_str("device"),      do: Device

  defp parse_syncable_str(str) do
    debug_log "no such syncable: #{str}"
    nil
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
