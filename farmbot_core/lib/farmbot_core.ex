defmodule Farmbot.Core do
  @moduledoc """
  Core Farmbot Services.
  This includes Logging, Configuration, Asset management and Firmware.
  """
  use Application

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @doc false
  def start(_, args), do: Supervisor.start_link(__MODULE__, args, name: __MODULE__)

  def start_link(args), do: Supervisor.start_link(__MODULE__, args, name: __MODULE__)

  def init([]) do
    children = [
      {Farmbot.Registry,                [] },
      {Farmbot.Logger.Supervisor,       [] },
      {Farmbot.Config.Supervisor,       [] },
      {Farmbot.Asset.Supervisor,        [] },
      {Farmbot.Firmware.Supervisor,     [] },
      {Farmbot.BotState,                [] },
      {Farmbot.CeleryScript.Supervisor, [] },
    ]
    Supervisor.init(children, [strategy: :one_for_one])
  end
end
