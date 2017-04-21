defmodule Farmbot.System.UeventHandler do
  @moduledoc """
    Handles Events from Linux.
  """
  use GenStage
  use Farmbot.DebugLog
  require Logger

  @mountpath "/tmp/drive"
  @target Mix.Project.config[:target]
  @app Mix.Project.config[:app]

  def start_link do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    # Starts a permanent subscription to the broadcaster
    # which will automatically start requesting items.
    {:consumer, :ok, subscribe_to: [Nerves.Runtime.Kernel.UEvent]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      handle_thing(event)
    end
    {:noreply, [], state}
  end

  defp handle_thing({:uevent, _, %{
      action: "add", devname: devname, devtype: "partition", subsystem: "block"
     }})
  do
    Logger.debug ">> Flash drive plugged in!!!"
    :ok = mount_part(devname)
    Logger.debug ">> Coppying logs!"
    File.cp "#{Farmbot.System.FS.path()}/logs.txt", "#{@mountpath}/logs.txt"

    :ok = maybe_flash_fw

    :ok = unmount_part(devname)
    :ok
  end

  defp handle_thing(_event) do
    debug_log("Not Handling uevent.")
    :ok
  end

  defp mount_part(devname) do
    Logger.debug ">> Mounting flash drive storage!"
    :ok = File.mkdir_p(@mountpath)
    :ok = System.cmd("mount", ["-t", "vfat", "/dev/#{devname}", "#{@mountpath}"])
    |> check_mount(devname)
    :ok
  end

  defp unmount_part(devname) do
    Logger.debug ">> Unmounting flash drive storage!"
    :ok = System.cmd("umount", ["/dev/#{devname}"]) |> check_mount(devname)
  end

  defp check_mount({_, 0}, _devname), do: :ok
  defp check_mount({err, _}, devname) do
    Logger.error ">> Error mounting or unmounting #{devname}! #{inspect err}"
    {:error, err}
  end

  defp maybe_flash_fw do
    fw_file = "#{@mountpath}/firmware.hex"
    os_file = "#{@mountpath}/#{@app}-#{@target}.fw"

    debug_log "Checking for emergency flash files."
    IO.inspect {fw_file, os_file}

    case File.stat(fw_file) do
      {:ok, _file} ->  handle_arduino(fw_file)
      _ -> debug_log "No fw file found."
    end

    case File.stat(os_file) do
      {:ok, _file} -> handle_os(os_file)
      _ -> debug_log "No os fw file found."
    end

    :ok
  end

  defp handle_os(file) do
    Nerves.Firmware.upgrade_and_finalize(file)
    Nerves.Firmware.reboot
  end

  defp handle_arduino(file) do
    errrm = fn() ->
      receive do
        :done ->
          :ok
        {:error, reason} -> {:error, reason}
      end
    end

    Logger.info ">> is installing a firmware update. "
      <> " I may act weird for a moment", channels: [:toast]

    pid = Process.whereis(Farmbot.Serial.Handler)

    if pid do
      GenServer.cast(Farmbot.Serial.Handler, {:update_fw, file, self()})
      errrm.()
    else
      Logger.info "doing some magic..."
      herp = Nerves.UART.enumerate()
      |> Map.drop(["ttyS0","ttyAMA0"])
      |> Map.keys
      case herp do
        [tty] ->
          Logger.info "magic complete!"
          Farmbot.Serial.Handler.flash_firmware(tty, file, self())
          errrm.()
        _ ->
          Logger.warn "Please only have one serial device when updating firmware"
          {:error, :could_not_detect_tty}
      end
    end
  end
  
end
