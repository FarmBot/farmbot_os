defmodule Farmbot.CeleryScript.Command.SendMessage do
  @moduledoc """
    SendMessage
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.CeleryScript.Ast
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
  @type message_channel :: Farmbot.Logger.rpc_message_channel

  @spec run(%{message: String.t, message_type: message_type}, [Ast.t])
    :: no_return
  def run(%{message: m, message_type: m_type}, channels) do
    rendered = Mustache.render(m, get_message_stuff())
    Logger.info ">> #{rendered}", type: m_type, channels: parse_channels(channels)
  end

  @spec get_message_stuff :: %{x: Command.x, y: Command.y, z: Command.z}
  defp get_message_stuff do
    [x, y, z] = Farmbot.BotState.get_current_pos
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
