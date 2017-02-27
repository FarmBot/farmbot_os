defmodule Module.concat([Farmbot,System,"host"]) do
  @moduledoc false
  @halt_on_exit Application.get_env(:farmbot, :halt_on_reset, true)
  @behaviour Farmbot.System
  def reboot, do: :ok
  def power_off, do: :ok
  def factory_reset do
    Farmbot.System.FS.transaction fn() ->
      File.rm_rf "/tmp/config.json"
      File.rm_rf "/tmp/secret"
      File.rm_rf "/tmp/farmware"
      System.halt(0)
    end
  end
end
