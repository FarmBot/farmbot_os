defmodule Module.concat([Farmbot, System, "host"]) do
  @moduledoc false
  @behaviour Farmbot.System

  def reboot, do: :ok
  def power_off, do: :ok

  def factory_reset(reason) do
    Farmbot.System.FS.transaction fn() ->
      File.rm_rf! "#{path()}"
      File.mkdir_p! "#{path()}"
      File.write("#{path()}/factory_reset_reason", reason)
    end, true
    System.halt(0)
  end

  defp path, do: Farmbot.System.FS.path()
end
