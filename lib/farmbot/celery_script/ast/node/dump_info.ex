defmodule Farmbot.CeleryScript.AST.Node.DumpInfo do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  use Farmbot.Logger
  import Farmbot.System.ConfigStorage, [only: [get_config_value: 3]]
  allow_args []
  def execute(%{}, [], env) do
    fw_data = if pid = Process.whereis(Farmbot.Firmware) do
      fw_state = :sys.get_state(pid).state
      serial_port = (Application.get_env(:farmbot, :behaviour)[:firmware_handler] ==
                    Farmbot.Firmware.UartHandler) &&
                    (Application.get_env(:farmbot, :uart_handler)[:tty]) || nil
      %{
        firmware_hardware: get_config_value(:string, "settings", "firmware_hardware"),
        firmware_version: Application.get_env(:farmbot, :expected_fw_versions) |> Enum.at(0) |> String.trim_trailing(".F"),
        locked: Farmbot.BotState.locked?(),
        busy: !fw_state.idle,
        serial_port: serial_port,
        current_command: inspect(fw_state.current)
      }
    else
      %{error: "Firmware process is not running. Could not collect info."}
    end
    |> Farmbot.JSON.encode!()
    data = %{
      fbos_commit: Farmbot.Project.commit(),
      fbos_version: Farmbot.Project.version(),
      firmware_commit: Farmbot.Project.arduino_commit(),
      network_interface: Farmbot.System.ConfigStorage.get_all_network_configs |> Enum.at(0) |> Map.get(:name),
      fbos_dmesg_dump: System.cmd("dmesg", []) |> elem(0),
      firmware_state: fw_data
    }
    json = Farmbot.JSON.encode!(data)
    case Farmbot.HTTP.post("/api/diagnostic_dumps", json) do
      {:ok, _} ->
        Logger.success 3, "Diagnostic report uploaded."
        {:ok, env}
      {:error, _} -> {:error, "post failed", env}
    end
  end
end
