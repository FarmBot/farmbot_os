defmodule Farmbot.System.NervesCommon do
  @moduledoc """
    Common functionality for nerves devices.
  """
  defmacro __using__(target: _) do
    quote do
      def reboot(), do: Nerves.Firmware.reboot()

      def power_off(), do: Nerves.Firmware.poweroff()

      def factory_reset() do
        Farmbot.System.FS.transaction fn() ->
          File.rm_rf "#{path()}/config.json"
          File.rm_rf "#{path()}/secret"
          reboot()
        end
      end

      defp path, do: Farmbot.System.FS.path()
    end
  end
end
