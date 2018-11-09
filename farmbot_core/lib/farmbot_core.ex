defmodule Farmbot.Core do
  @moduledoc """
  Core Farmbot Services.
  This includes Logging, Configuration, Asset management and Firmware.
  """
  use Application

  @doc false
  def start(_, args), do: Supervisor.start_link(__MODULE__, args, name: __MODULE__)

  def init([]) do
    children = [
      {Farmbot.BotState,                []},
      {Farmbot.Logger.Supervisor,       []},
      {Farmbot.Config.Supervisor,       []},
      {Farmbot.Asset.Supervisor,        []},
      {Farmbot.Core.FirmwareSupervisor,     []},
      {Farmbot.Core.CeleryScript.Supervisor, []},
    ]
    Supervisor.init(children, [strategy: :one_for_all])
  end
end
