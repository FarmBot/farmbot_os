defmodule FarmbotOS.SysCalls.DumpInfo do
  @moduledoc false
  require FarmbotCore.Logger
  alias FarmbotCore.{Asset, Asset.Private, Config, Project}

  def dump_info do
    FarmbotCore.Logger.busy(1, "Recording diagnostic dump.")
    ifname = get_network_config()
    dmesg = dmesg()
    fbos_commit = Project.commit()
    fbos_version = Project.version()
    fw_version = fw_version()
    fw_commit = Project.arduino_commit()
    fw_hardware = extract_fw_hardware(fw_version)
    fw_data = fw_state(fw_version, fw_hardware)

    params = %{
      network_interface: ifname,
      firmware_hardware: fw_hardware,
      firmware_commit: fw_commit,
      fbos_commit: fbos_commit,
      fbos_version: fbos_version,
      fbos_dmesg_dump: dmesg,
      firmware_state: FarmbotCore.JSON.encode!(fw_data)
    }

    case Asset.new_diagnostic_dump(params) do
      {:ok, diag} ->
        _ = Private.mark_dirty!(diag, %{})
        FarmbotCore.Logger.success(1, "Diagnostic dump recorded.")
        :ok

      {:error, changeset} ->
        {:error, "error creating diagnostic dump: #{inspect(changeset)}"}
    end
  end

  defp get_network_config do
    case Config.get_all_network_configs() do
      [%{name: ifname} | _] -> ifname
      _ -> nil
    end
  end

  defp dmesg do
    {dmesg, _status} = System.cmd("dmesg", [])
    dmesg
  end

  defp fw_version do
    case FarmbotFirmware.request({:software_version_read, []}) do
      {:ok, {_, {:report_software_version, [version]}}} -> version
      _ -> nil
    end
  end

  defp extract_fw_hardware(nil), do: nil

  defp extract_fw_hardware(str) do
    case String.split(str, ".") do
      [_, _, _, "G"] -> "farmduino_k14"
      [_, _, _, "F"] -> "farmduino"
      [_, _, _, "R"] -> "arduino"
      _ -> nil
    end
  end

  defp fw_state(version, hardware) do
    pid = Process.whereis(FarmbotFirmware)

    if state = pid && :sys.get_state(pid) do
      %{
        firmware_hardware: hardware,
        firmware_version: version,
        busy: state.status == :busy,
        serial_port: state.transport_args[:device],
        locked: state.status == :emergency_lock,
        current_command: inspect(state.command_queue)
      }
    else
      %{error: "Firmware process is not running. Could not collect info."}
    end
  end
end
