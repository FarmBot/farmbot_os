defmodule FarmbotOS.FarmwareRuntime.RunCommand do
  @moduledoc """
  Command execution wrapper to make testing possible.
  """

  def run(cmd_args) do
    spawn_monitor(MuonTrap, :cmd, cmd_args)
  end
end
