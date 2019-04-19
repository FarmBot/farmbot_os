defmodule FarmbotOS.Init.Supervisor do
  @moduledoc """
  All the stuff that needs to start before
  FarmBotOS gets supervised by this one.

  Handles boot logic for FBOS (on host vs. RPi).
  """

  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    config = Application.get_env(:farmbot, __MODULE__)

    children =
      (config[:init_children] || []) ++
        [
          FarmbotOS.Init.FSCheckup,
          FarmbotOS.Init.AlertFirmwareMissing
        ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
