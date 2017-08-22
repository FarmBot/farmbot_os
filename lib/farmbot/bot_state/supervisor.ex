defmodule Farmbot.BotState.Supervisor do
  @moduledoc "Supervises BotState stuff."

  use Supervisor
  alias Farmbot.BotState
  alias Farmbot.BotState.{
    InformationalSettings, Configuration, LocationData, ProcessInfo, McuParams,
    Transport
  }

  alias Farmbot.Firmware, as: FW

  @doc "Start the BotState stack."
  def start_link(token, opts \\ []) do
    Supervisor.start_link(__MODULE__, token, opts)
  end

  def init(token) do
    children = [
      # BotState parts.
      worker(BotState,                 [[name: BotState]]),
      worker(InformationalSettings,    [BotState, [name: InformationalSettings]]),
      worker(Configuration,            [BotState, [name: Configuration]]),
      worker(LocationData,             [BotState, [name: LocationData]]),
      worker(ProcessInfo,              [BotState, [name: ProcessInfo]]),
      worker(McuParams,                [BotState, [name: McuParams]]),

      # Transport part.
      supervisor(Transport.Supervisor, [token, BotState, [name: Transport.Supervisor]]),

      # Firmware part.
      supervisor(FW.Supervisor, [BotState, InformationalSettings, Configuration, LocationData, McuParams, [name: FW.Supervisor]]),

      # Farmware.
      supervisor(Farmbot.Farmware.Supervisor, [token, BotState, ProcessInfo, [name: Farmbot.Farmware.Supervisor]])
    ]
    # We set one_for_all here, since all of these link to `BotState`
    supervise(children, [strategy: :one_for_all])
  end
end
