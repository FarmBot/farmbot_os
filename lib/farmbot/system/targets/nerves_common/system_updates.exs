defmodule Farmbot.System.NervesCommon.Updates do
  defmacro __using__(target: _) do
    quote do
      @behaviour Farmbot.System.Updates
      require Logger
      
      @expected_fw_version Application.get_env(Mix.Project.config[:app],
        :expected_fw_version)

      def install(path), do: :ok = Nerves.Firmware.upgrade_and_finalize(path)

      defp blerp(tries \\ 0)
      defp blerp(tries) when tries > 10 do
        Logger.error "No serial handler"
        :ok
      end
      defp blerp(tries) do
        pid = Process.whereis(Farmbot.Serial.Handler)
        if is_pid(pid) do
          :ok
        else
          Logger.warn "No serial handler yet, waiting..."
          Process.sleep(5000)
          blerp(tries + 1)
        end
      end

      def post_install do
        :ok = blerp()
        r = Farmbot.Serial.Handler.write "F83"
        case r do
          {:report_software_version, @expected_fw_version} ->
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
