defmodule Module.concat([Farmbot, System, "rpi3"]) do
  @moduledoc false
  @behaviour Farmbot.System

  def reboot(), do: Nerves.Firmware.reboot()

  def power_off(), do: Nerves.Firmware.poweroff()

  def factory_reset() do
    Farmbot.System.FS.transaction fn() ->
      File.rm_rf "#{path}/config.json"
      File.rm_rf "#{path}/secret"
      reboot()
    end
  end

  defp path, do: Farmbot.System.FS.path()
end
