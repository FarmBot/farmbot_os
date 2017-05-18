defmodule Farmbot.CeleryScript.Command.SendMessage do
  @moduledoc """
    SendMessage
  """

  alias Farmbot.CeleryScript.{Command, Ast}
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

  @spec run(%{message: String.t, message_type: message_type}, [Ast.t], Ast.context)
    :: Ast.context
  def run(%{message: m, message_type: m_type}, channels, context) do
    rendered = Mustache.render(m, get_message_stuff(context))
    Logger.info ">> #{rendered}", type: m_type, channels: parse_channels(channels)
    context
  end

  @spec get_message_stuff(Ast.context) :: %{x: Command.x, y: Command.y, z: Command.z}
  defp get_message_stuff(context) do
    [x, y, z] = Farmbot.BotState.get_current_pos(context)
    %{x: x, y: y, z: z}
  end

  @spec parse_channels([Ast.t]) :: [message_channel]
  defp parse_channels(l) do
    {ch, _} = Enum.partition(l, fn(channel_ast) ->
      channel_ast.args["channel_name"]
    end)
    ch
  end
end
