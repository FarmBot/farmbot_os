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
  alias Farmbot.Context
  def start_link(%Context{} = ctx, _target, opts) do
    GenStage.start_link(__MODULE__, ctx, opts)
  end

  def init(ctx) do
    # Starts a permanent subscription to the broadcaster
    # which will automatically start requesting items.
    {:consumer, ctx, subscribe_to: [Nerves.Runtime.Kernel.UEvent]}
  end

  def handle_events(events, _from, ctx) do
    for event <- events do
      handle_thing(event, ctx)
    end
    {:noreply, [], ctx}
  end

  defp handle_thing({:uevent, _, %{
      action: "add", devname: devname, devtype: "partition", subsystem: "block"
     }}, _ctx)
  do
    Logger.debug ">> Flash drive plugged in!!!"
    :ok = mount_part(devname)
    Logger.debug ">> Coppying logs!"
    File.cp "#{Farmbot.System.FS.path()}/logs.txt", "#{@mountpath}/logs.txt"

    :ok = maybe_flash_fw()

    :ok = unmount_part(devname)
    :ok
  end

  defp handle_thing({:uevent, _, %{
    action: "add", devname: _tty, subsystem: "tty"
  }}, %Context{} = ctx) do
    pid =
      case ctx.serial do
        serial when is_atom(serial) -> Process.whereis(serial)
        serial when is_pid(serial)  -> serial
      end
    alive? =
      if pid do
        Process.alive?(pid)
      end

    if alive? do
      debug_log "Already have a serial handler. Not making a new one."
    else
      debug_log "Going to try to start a new serial handler."
      Farmbot.Serial.Handler.OpenTTY.open_ttys(ctx, Farmbot.Serial.Supervisor)
    end
  end

  defp handle_thing(event, _ctx) do
    debug_log("Not Handling uevent: #{inspect event}")
    :ok
  end

  defp mount_part(devname) do
    Logger.debug ">> Mounting flash drive storage!"
    :ok = File.mkdir_p(@mountpath)
    :ok = "mount" |> System.cmd(["-t", "vfat", "/dev/#{devname}", "#{@mountpath}"])
    |> check_mount(devname)
    :ok
  end

  defp unmount_part(devname) do
    Logger.debug ">> Unmounting flash drive storage!"
    :ok = "umount" |> System.cmd(["/dev/#{devname}"]) |> check_mount(devname)
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
    ctx = Farmbot.Context.new()

    pid = Process.whereis(ctx.serial)

    if pid do
      GenServer.cast(ctx.serial, {:update_fw, file, self()})
      errrm.()
    else
      Logger.info "doing some magic..."
      herp = Nerves.UART.enumerate()
      |> Map.drop(["ttyS0","ttyAMA0"])
      |> Map.keys
      case herp do
        [tty] ->
          Logger.info "magic complete!"
          Farmbot.Serial.Handler.flash_firmware(ctx, tty, file, self())
          errrm.()
        _ ->
          Logger.warn "Please only have one serial device when updating firmware"
          {:error, :could_not_detect_tty}
      end
    end
  end

end
