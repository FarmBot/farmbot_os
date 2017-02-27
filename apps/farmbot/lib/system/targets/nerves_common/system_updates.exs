defmodule Farmbot.System.NervesCommon.Updates do
  defmacro __using__(target: _) do
    quote do
      def install(path) do
        Nerves.Firmware.upgrade_and_finalize(path)
      end
    end
  end
end
