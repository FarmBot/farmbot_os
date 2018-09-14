defmodule Farmbot.System.Init.KernelMods do
  @moduledoc "Loads kernel modules at boot."
  
  use Supervisor
  use Farmbot.Logger
  @mods Application.get_env(:farmbot, :kernel_modules, [])

  def start_link(_, opts \\ []) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    do_checkup()
    :ignore
  end

  defp do_checkup do
    for mod <- @mods do
      Logger.debug 3, "Loading kernel module: #{mod}"
      System.cmd "modprobe", [mod], into: IO.stream(:stdio, :line)
    end
  end
end
