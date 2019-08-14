defmodule FarmbotCore.AssetHelpers do
  @moduledoc """
  Helpers for the console at runtime.
  
  Example:
     iex()> use FarmbotCore.AssetHelpers
     iex()> Repo.all(Device)
     [%Device{}]
  """
  
  @doc false
  defmacro __using__(_opts) do
    require Logger
    Logger.warn "Don't use this in production please!"
    quote do
      import Ecto.Query
      alias FarmbotCore.Asset
      alias Asset.{
        Repo,
        Device,
        DeviceCert,
        DiagnosticDump,
        FarmwareEnv,
        FarmwareInstallation,
        FirstPartyFarmware,
        FarmEvent,
        FbosConfig,
        FirmwareConfig,
        Peripheral,
        PinBinding,
        Point,
        PublicKey,
        Regimen,
        RegimenInstance,
        Sequence,
        Sensor,
        SensorReading,
        Tool
      }
    end
  end
end