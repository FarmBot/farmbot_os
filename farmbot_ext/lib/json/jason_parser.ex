defmodule Farmbot.JSON.JasonParser do
  @moduledoc "Parser handler for Jason"
  @behaviour Farmbot.JSON.Parser

  def decode(data), do: Jason.decode(data)
  def encode(data), do: Jason.encode(data)

  require Protocol
  Protocol.derive(Jason.Encoder, Farmbot.Jwt)
  Protocol.derive(Jason.Encoder, Farmbot.BotState)
  Protocol.derive(Jason.Encoder, Farmbot.BotState.Configuration)
  Protocol.derive(Jason.Encoder, Farmbot.BotState.InformationalSettings)
  Protocol.derive(Jason.Encoder, Farmbot.BotState.LocationData)
  Protocol.derive(Jason.Encoder, Farmbot.BotState.McuParams)
  Protocol.derive(Jason.Encoder, Farmbot.BotState.Pin)
end
