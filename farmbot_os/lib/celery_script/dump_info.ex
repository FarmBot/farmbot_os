defmodule Farmbot.OS.IOLayer.DumpInfo do
  @moduledoc false

  alias Farmbot.{Firmware, Asset, Config, Project}

  def execute(_args, _body) do
    conf = Asset.fbos_config()
    fw_state = get_fw_state(Process.whereis(Firmware), conf)
    network_iface = Config.get_all_network_configs() |> Enum.at(0)

    params = %{
      firmware_state: fw_state,
      network_interface: network_iface[:name],
      firmware_hardware: fw_state[:firmware_hardware],
      fbos_commit: Project.commit(),
      fbos_version: Project.version(),
      fbos_dmesg_dump: System.cmd("dmesg", []) |> elem(0),
      fbos_target: Project.target()
    }

    case Farmbot.Asset.new_diagnostic_dump(params) do
      {:ok, _} -> :ok
      {:error, _} -> {:error, "Failed to create diagnostic dump"}
    end
  end

  def get_fw_state(nil, _), do: nil

  def get_fw_state(fw, conf) do
    %{
      firmware_hardware: conf.firmware_hardware,
      firmware_version: firmware_version(fw),
      busy: false,
      serial_port: conf.firmware_path,
      locked: false,
      current_command: nil
    }
  end

  defp firmware_version(fw) do
    case Firmware.request(fw, {:software_version_read, []}) do
      {:ok, {_, {:report_software_version, [ver]}}} -> ver
      _error -> nil
    end
  end
end
