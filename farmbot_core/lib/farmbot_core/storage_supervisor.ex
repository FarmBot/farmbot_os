defmodule FarmbotCore.StorageSupervisor do
  @moduledoc """
  Top-level supervisor for REST resources (Asset), configs and the logger.
  """

  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    Supervisor.init(children(), [strategy: :one_for_one])
  end

  def children do
    default = [
      FarmbotCore.Logger.Supervisor,
      FarmbotCore.Config.Supervisor,
      FarmbotCore.Asset.Supervisor,
      FarmbotCore.Firmware.UARTObserver,
    ]
    config = Application.get_env(:farmbot_core, __MODULE__) || []
    Keyword.get(config, :children, default)
  end
end
