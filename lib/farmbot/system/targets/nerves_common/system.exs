defmodule Farmbot.System.NervesCommon do
  @moduledoc """
    Common functionality for nerves devices.
  """
  defmacro __using__(target: _) do
    quote do
      def reboot, do: Nerves.Firmware.reboot()

      def power_off, do: Nerves.Firmware.poweroff()

      def factory_reset(reason) do
        Farmbot.System.FS.transaction fn() ->
          File.rm_rf "#{path()}/config.json"
          File.rm_rf "#{path()}/secret"
          File.rm_rf "#{path()}/farmware"
          File.write("#{path()}/factory_reset_reason", reason)
        end, true
        reboot()
      end

      defp path, do: Farmbot.System.FS.path()
    end
  end
end
