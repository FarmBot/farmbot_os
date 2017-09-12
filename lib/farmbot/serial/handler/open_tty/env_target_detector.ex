defmodule Farmbot.Serial.Handler.OpenTTY.EnvTargetDetector do
  @moduledoc false

  @doc false
  defmacro test_host do
    quote do
      @doc false
      def try_detect_tty do
        debug_log "using test/host tty opener."
        nil
      end
    end
  end

  @doc false
  defmacro dev_host do
    quote do
      @doc false
      def try_detect_tty do
        debug_log "using dev/host tty opener."
        System.get_env("ARDUINO_TTY")
      end
    end
  end

  @doc false
  defmacro target(_, _target) do
    quote do
      require Logger
      @doc false
      def try_detect_tty do
        debug_log "using rpi3 tty opener."
        Nerves.UART.enumerate()
          |> Map.keys()
          |> Kernel.--(["ttyAMA0", "ttyS0"])
          |> check_and_return()
      end

      defp check_and_return([tty]) do
        debug_log "Detected tty: #{tty}"
        check_fw(tty)
        tty
      end

      defp check_and_return([]) do
        debug_log "didnt detect any serial devices."
        Logger.info ">> Could not find an Arduino!", type: :error
        nil
      end

      defp check_and_return(_to_many) do
        debug_log "too many serial devices."
        Logger.info ">> Found too many serial devices!", type: :error
        nil
      end

      defp check_fw(tty) do
        case File.read("/state/needs_fw_flash") do
          {:ok, _version} ->
            # file = :
            :os.cmd('avrdude -patmega2560 -cwiring -P/dev//dev/ttyUSB0 -b115200 -D -q -V -Uflash:w:/tmp/file.hex:i')
          _ -> :ok
        end
      end
    end
  end
end
