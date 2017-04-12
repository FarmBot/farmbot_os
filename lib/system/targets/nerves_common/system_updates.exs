defmodule Farmbot.System.NervesCommon.Updates do
  defmacro __using__(target: _) do
    quote do
      @behaviour Farmbot.System.Updates
      require Logger
      @expected_version "GENESIS V.01.08.EXPERIMENTAL"

      def install(path), do: Nerves.Firmware.upgrade_and_finalize(path)

      defp blerp do
        pid = Process.whereis(Farmbot.Serial.Handler)
        if is_pid(pid) do
          :ok
        else
          Logger.warn "No serial handler yet, waiting..."
          Process.sleep(5000)
          blerp()
        end
      end

      def post_install do
        :ok = blerp()
        r = Farmbot.Serial.Handler.write "F83"
        case r do
          {:report_software_version, @expected_version} ->
            Logger.info "Firmware is already the correct version!"
            :ok
          _ ->
            # we need to flash the firmware
            file = "#{:code.priv_dir(:farmbot)}/firmware.hex"
            Logger.warn "UPDATING FIRMWRE!!"
            GenServer.cast(Farmbot.Serial.Handler, {:update_fw, file, self()})
            wait_for_finish()
        end
      end

      defp wait_for_finish do
        receive do
          :done -> :ok
          _e -> :ok
        end
      end

    end
  end
end
