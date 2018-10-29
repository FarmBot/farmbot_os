defmodule Farmbot.JSON.JasonParser do
  @moduledoc "Parser handler for Jason"
  @behaviour Farmbot.JSON.Parser

  def decode(data, opts), do: Jason.decode(data, opts)
  def encode(data, opts), do: Jason.encode(data, opts)

  require Protocol
  # Bot State
  Protocol.derive Jason.Encoder, Farmbot.BotState
  Protocol.derive Jason.Encoder, Farmbot.BotState.Configuration
  Protocol.derive Jason.Encoder, Farmbot.BotState.InformationalSettings
  Protocol.derive Jason.Encoder, Farmbot.BotState.LocationData
  Protocol.derive Jason.Encoder, Farmbot.BotState.McuParams
  Protocol.derive Jason.Encoder, Farmbot.BotState.Pin
end
