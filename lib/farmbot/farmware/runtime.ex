defmodule Farmbot.Farmware.Runtime do
  @moduledoc "Handles execution of a Farmware."

  alias Farmbot.Farmware
  alias Farmware.{RuntimeError, Installer}
  use Farmbot.Logger

  defstruct [:farmware, :env, :port, :exit_status, :working_dir, :return_dir]

  @doc "Execute a Farmware struct."
  def execute(%Farmware{} = farmware) do
    Logger.busy 2, "Beginning execution of #{inspect farmware}"
    fw_path = Installer.install_path(farmware) |> Path.absname("#{:code.priv_dir(:farmbot)}/..")
    with {:ok, cwd} <- File.cwd(),
         :ok        <- File.cd(fw_path),
         env        <- build_env(farmware)
    do
      exec = farmware.executable
      opts = [:stream,
              :binary,
              :exit_status,
              :hide,
              :use_stdio,
              :stderr_to_stdout,
              args: farmware.args,
              env: env ]
      port = Port.open({:spawn_executable, exec}, opts)
      handle_port(struct(__MODULE__, [port: port, env: env, farmware: farmware, working_dir: fw_path, return_dir: cwd]))
    else
      {:error, err} -> raise RuntimeError, [state: nil, message: err]
    end
    |> do_cleanup()
  end

  defp do_cleanup(%__MODULE__{return_dir: return_dir} = state) do
    File.cd(return_dir)
    state
  end

  defp handle_port(%__MODULE__{port: port, farmware: farmware} = state) do
    receive do
      {^port, {:exit_status, 0}}      ->
        Logger.success 2, "#{inspect farmware} completed without errors."
        %{state | exit_status: 0}
      {^port, {:exit_status, status}} ->
        Logger.warn 2, "#{inspect farmware} completed with exit status: #{status}"
        %{state | exit_status: status}
      {^port, {:data, data}} ->
        Logger.info 3, "[#{inspect farmware}] sent data: \r\n\=\=\=\=\=\=\=\=\=\=\=\r\n\r\n#{data} \r\n\=\=\=\=\=\=\=\=\=\=\=", color: :NC
        handle_port(state)
    end
  end

  defp build_env(%Farmware{config: config, name: fw_name} = _farmware) do
    token = Farmbot.System.ConfigStorage.get_config_value(:string, "authorization", "token")
    images_dir = "/tmp/images"

    config
      |> Enum.filter(&match?(%{"label" => _, "name" => _, "value" => _}, &1))
      |> Map.new(&format_config(fw_name, &1))
      |> Map.put("API_TOKEN", token)
      |> Map.put("FARMWARE_TOKEN", token)
      |> Map.put("IMAGES_DIR", images_dir)
      |> Map.put("FARMWARE_URL", "http://localhost:27347/")
      |> Map.merge(Farmbot.BotState.get_user_env())
      |> Enum.map(fn({key, val}) -> {to_erl_safe(key), to_erl_safe(val)} end)
  end

  defp format_config(fw_name, %{"label" => _, "name" => name, "value" => val}) do
    sep = case String.contains?(fw_name, "-") do
      true -> "-"
      false -> " "
    end
    ns = String.split(fw_name, sep) |> Enum.join() |> Macro.underscore
    {"#{ns}_#{name}", val}
  end

  defp to_erl_safe(binary) when is_binary(binary), do: to_charlist(binary)
  defp to_erl_safe(map) when is_map(map), do: map |> Poison.encode! |> to_erl_safe()
  defp to_erl_safe(number) when is_number(number), do: number
end
