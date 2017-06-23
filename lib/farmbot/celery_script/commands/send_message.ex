defmodule Farmbot.CeleryScript.Command.SendMessage do
  @moduledoc """
    SendMessage
  """

  alias      Farmbot.CeleryScript.{Command, Types}
  alias      Farmbot.Context
  require    Logger
  @behaviour Command

  @doc ~s"""
    Logs a message to some places
      args: %{},
      body: []
  """
  @type message_type :: binary
  # "info"
  # "fun"
  # "warn"
  # "error"
  @type message_channel :: Logger.Backends.FarmbotLogger.rpc_message_channel

  @spec run(%{message: binary, message_type: message_type},
    [Types.ast], Context.t) :: Context.t

  def run(%{message: m, message_type: m_type}, pairs, %Context{} = context) do
    rendered = Mustache.render(m, get_message_stuff(context, pairs))
    Logger.info ">> #{rendered}",
      type: m_type, channels: parse_channels(pairs)
    context
  end

  @spec get_message_stuff(Context.t, [Types.ast])
    :: %{x: Types.coord_x, y: Types.coord_y, z: Types.coord_z}
  defp get_message_stuff(%Context{} = context, _pairs) do
    [x, y, z] = Farmbot.BotState.get_current_pos(context)
    coords    = %{x: x, y: y, z: z}
    pins      = Map.new(0..70, fn(num) ->
                      pin_val =
                        case Farmbot.BotState.get_pin(context, num) do
                          %{value: val} -> val
                          _             -> :unknown
                        end
                      {:"pin#{num}", pin_val}
                    end)
    Map.merge(coords, pins)
  end

  @spec parse_channels([Types.ast]) :: [message_channel]
  defp parse_channels(l) do
    channels = Enum.filter(l, fn(ast) -> ast.kind == "channel" end)
    Enum.map(channels, fn(%{kind: "channel", args: %{channel_name: ch}}) ->
      ch
    end)
  end
end
