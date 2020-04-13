Application.get_env(:farmbot, FarmbotOS.SysCalls.FlashFirmware, [])[:gpio]

defmodule FarmbotOS.SysCalls.FlashFirmware do
  @moduledoc false

  alias FarmbotCore.{Asset, Asset.Private}
  alias FarmbotFirmware
  alias FarmbotCore.FirmwareTTYDetector

  defmodule Stub do
    require FarmbotCore.Logger

    def fail do
      m = "No express function found. Please notify support."
      FarmbotCore.Logger.error(3, m)
      {:error, m}
    end

    def open(_, _), do: fail()
    def write(_, _), do: fail()
  end

  # This only matter for express.
  # When it's an express, use Circuits.GPIO.
  @gpio Application.get_env(:farmbot, __MODULE__, [])[:gpio] || Stub

  import FarmbotFirmware.PackageUtils,
    only: [find_hex_file: 1, package_to_string: 1]

  require FarmbotCore.Logger
  require Logger

  def flash_firmware(package) do
    FarmbotCore.Logger.busy(
      2,
      "Flashing #{package_to_string(package)} firmware"
    )

    with {:ok, hex_file} <- find_hex_file(package),
         {:ok, tty} <- find_tty(),
         _ <-
           FarmbotCore.Logger.debug(3, "found tty: #{tty} for firmware flash"),
         {:ok, fun} <- find_reset_fun(package),
         _ <-
           FarmbotCore.Logger.debug(
             3,
             "closing firmware transport before flash"
           ),
         :ok <- FarmbotFirmware.close_transport(),
         _ <- FarmbotCore.Logger.debug(3, "starting firmware flash"),
         _ <- finish_flashing(Avrdude.flash(hex_file, tty, fun)) do
      %{firmware_path: tty}
      |> Asset.update_fbos_config!()
      |> Private.mark_dirty!(%{})

      :ok
    else
      {:error, reason} when is_binary(reason) ->
        {:error, reason}

      error ->
        {:error, "flash_firmware returned #{inspect(error)}"}
    end
  end

  def finish_flashing({_result, 0}) do
    FarmbotCore.Logger.success(2, "Firmware flashed successfully!")
  end

  def finish_flashing(result) do
    FarmbotCore.Logger.debug(2, "AVR flash returned #{inspect(result)}")
  end

  defp find_tty() do
    case FirmwareTTYDetector.tty() do
      nil ->
        {:error,
         """
         No suitable TTY detected. Check cables and try again.
         """}

      tty ->
        {:ok, tty}
    end
  end

  defp find_reset_fun("express_k10") do
    FarmbotCore.Logger.debug(3, "Using special express reset function")
    {:ok, fn -> express_reset_fun() end}
  end

  defp find_reset_fun(_) do
    FarmbotCore.Logger.debug(3, "Using default reset function")
    {:ok, &FarmbotFirmware.NullReset.reset/0}
  end

  def express_reset_fun() do
    try do
      FarmbotCore.Logger.debug(3, "Begin MCU reset")
      {:ok, gpio} = @gpio.open(19, :output)
      :ok = @gpio.write(gpio, 0)
      :ok = @gpio.write(gpio, 1)
      Process.sleep(1000)
      :ok = @gpio.write(gpio, 0)
      FarmbotCore.Logger.debug(3, "Finish MCU Reset")
      :ok
    rescue
      ex ->
        message = Exception.message(ex)
        Logger.error("Could not flash express firmware: #{message}")
        :express_reset_error
    end
  end
end
