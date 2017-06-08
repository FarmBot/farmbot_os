defmodule Farmbot.CeleryScript.Command.SendMessage do
  @moduledoc """
    SendMessage
  """

  alias   Farmbot.CeleryScript.{Command, Ast}
  alias   Farmbot.Context
  import  Command, only: [read_pin_or_raise: 3]
  require Logger

  @behaviour Command

  @doc ~s"""
    Logs a message to some places
      args: %{},
      body: []
  """
  @type message_type :: String.t
  # "info"
  # "fun"
  # "warn"
  # "error"
  @type message_channel :: Logger.Backends.FarmbotLogger.rpc_message_channel

  @spec run(%{message: String.t, message_type: message_type},
    [Ast.t], Ast.context) :: Ast.context

  def run(%{message: m, message_type: m_type}, pairs, %Context{} = context) do
    rendered = Mustache.render(m, get_message_stuff(context, pairs))
    Logger.info ">> #{rendered}",
      type: m_type, channels: parse_channels(pairs)
    context
  end

  @spec get_message_stuff(Ast.context, [Ast.t])
    :: %{x: Command.x, y: Command.y, z: Command.z}
  defp get_message_stuff(%Context{} = context, pairs) do
    [x, y, z] = Farmbot.BotState.get_current_pos(context)
    coords    = %{x: x, y: y, z: z}
    pins      = Map.new(0..70, fn(num) ->
                      pin_val =
                        case Farmbot.BotState.get_pin(context, num) do
                          %{value: val} -> val
                          _             -> :unknown 
                            # read_pin_or_raise(context, num,  pairs)
                        end
                      {:"pin#{num}", pin_val}
                    end)
    Map.merge(coords, pins)
  end

  @spec parse_channels([Ast.t]) :: [message_channel]
  defp parse_channels(l) do
    channels = Enum.filter(l, fn(ast) -> ast.kind == "channel" end)
    Enum.map(channels, fn(%{kind: "channel", args: %{channel_name: ch}}) ->
      ch
    end)
  end
end
