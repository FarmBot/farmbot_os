defmodule Farmbot.CeleryScript.AST.Node.DumpInfo do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args []
  def execute(%{}, [], env) do
    data = %{
      fbos_version: Farmbot.Project.version(),
      firmware_commit: Farmbot.Project.arduino_commit(),
      network_interface: Farmbot.System.ConfigStorage.get_all_network_configs |> Enum.at(0) |> Map.get(:name),
      fbos_dmesg_dump: System.cmd("dmesg", []) |> elem(0),
      firmware_state: Application.get_env(:farmbot, :behaviour)[:firmware_handler] |> to_string()
    }
    json = Farmbot.JSON.encode!(data)
    case Farmbot.HTTP.post("/api/diagnostic_dumps", json) do
      {:ok, _} -> {:ok, env}
      {:error, _} -> {:error, "post failed", env}
    end
  end
end
