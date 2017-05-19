defmodule Farmbot.System.NervesCommon.Updates do
  defmacro __using__(target: _) do
    quote do
      @behaviour Farmbot.System.Updates
      require Logger

      def install(path), do: :ok = Nerves.Firmware.upgrade_and_finalize(path)

      defp blerp(tries \\ 0)

      defp blerp(tries) when tries > 10 do
        Logger.info "No serial handler", type: :warn
        :ok
      end

      defp blerp(tries) do
        ctx = Farmbot.Context.new()
        pid = Process.whereis(ctx.serial)
        if is_pid(pid) do
          r = Farmbot.Serial.Handler.write ctx, "F83"
          if r == :timeout do
            Logger.info "Got timeout waiting for serial handler. Trying again"
            blerp(tries + 1)
          else
            :ok
          end
        else
          Logger.info "No serial handler yet, waiting...", type: :warn
          Process.sleep(5000)
          blerp(tries + 1)
        end
      end

      def post_install do
        Logger.info ">> Is doing post install stuff."
        :ok = blerp()
        ctx = Farmbot.Context.new
        r = Farmbot.Serial.Handler.write ctx, "F83"
        exp = Application.get_all_env(:farmbot)[:expected_fw_version]
        case r do
          {:report_software_version, version} when version == exp ->
            Logger.info "Firmware is already the correct version!"
            :ok
          other ->
            # we need to flash the firmware
            IO.warn "#{inspect other}"
            file = "#{:code.priv_dir(:farmbot)}/firmware.hex"
            Logger.info ">> Doing post update firmware flash.", type: :warn
            GenServer.cast(ctx.serial, {:update_fw, file, self()})
            wait_for_finish()
        end
      end

      defp wait_for_finish do
        receive do
          :done -> :ok
          _e -> :reboot
        end
      end

    end
  end
end
