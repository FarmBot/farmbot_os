defmodule FarmbotOS.Init.Supervisor do
  @moduledoc """
  Supervises processes that needs to start before
  the rest of the FarmBotOS tree.

  Handles boot logic for FBOS (on host vs. RPi).
  """

  use Supervisor

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    config = Application.get_env(:farmbot, __MODULE__)

    children =
      (config[:init_children] || []) ++
        [
          FarmbotOS.Init.FSCheckup
        ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
