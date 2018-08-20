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

  # Assets
  Protocol.derive Jason.Encoder, Farmbot.Asset.Device
  Protocol.derive Jason.Encoder, Farmbot.Asset.FarmEvent
  Protocol.derive Jason.Encoder, Farmbot.Asset.FarmwareEnv
  Protocol.derive Jason.Encoder, Farmbot.Asset.FarmwareInstallation
  Protocol.derive Jason.Encoder, Farmbot.Asset.Peripheral
  Protocol.derive Jason.Encoder, Farmbot.Asset.PinBinding
  Protocol.derive Jason.Encoder, Farmbot.Asset.Point
  Protocol.derive Jason.Encoder, Farmbot.Asset.Regimen
  Protocol.derive Jason.Encoder, Farmbot.Asset.Sensor
  Protocol.derive Jason.Encoder, Farmbot.Asset.Sequence
  Protocol.derive Jason.Encoder, Farmbot.Asset.Tool
end
