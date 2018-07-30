defmodule Farmbot.Farmware.Runtime do
  @moduledoc "Handles execution of a Farmware."

  alias Farmbot.Farmware
  alias Farmware.{RuntimeError, Installer}
  use Farmbot.Logger

  @fbos_version Farmbot.Project.version()

  defstruct [:farmware, :env, :port, :exit_status, :working_dir, :return_dir]

  @doc "Execute a Farmware struct."
  def execute(%Farmware{} = farmware, env) when is_list(env) do
    Logger.busy(2, "Beginning execution of #{inspect(farmware)}")

    fw_path =
      Installer.install_path(farmware)
      |> Path.absname("#{:code.priv_dir(:farmbot)}/..")

    cwd = File.cwd!()

    with :ok <- File.cd(fw_path),
         env <- build_env(farmware, env) do
      exec =
        case farmware.executable do
          "./" <> exe ->
            file = Path.join(fw_path, exe)
            File.chmod(file, 0o777)
            file

          "/" <> _ ->
            farmware.executable
        end

      opts = [
        :stream,
        :binary,
        :exit_status,
        :hide,
        :use_stdio,
        :stderr_to_stdout,
        args: farmware.args,
        env: env
      ]

      # IO.puts "executing: #{exec} #{to_string(farmware.args)}"
      # IO.puts "env: #{inspect env}"

      port = Port.open({:spawn_executable, exec}, opts)

      handle_port(
        struct(
          __MODULE__,
          port: port,
          env: env,
          farmware: farmware,
          working_dir: fw_path,
          return_dir: cwd
        )
      )
    else
      {:error, err} ->
        File.cd(cwd)
        raise RuntimeError, state: nil, message: err
    end
    |> do_cleanup()
  end

  defp do_cleanup(%__MODULE__{return_dir: return_dir} = state) do
    File.cd(return_dir)
    state
  end

  defp handle_port(%__MODULE__{port: port, farmware: farmware} = state) do
    receive do
      {^port, {:exit_status, 0}} ->
        Logger.success(2, "#{inspect(farmware)} completed without errors.")
        %{state | exit_status: 0}

      {^port, {:exit_status, status}} ->
        Logger.warn(
          2,
          "#{inspect(farmware)} completed with exit status: #{status}"
        )

        %{state | exit_status: status}

      {^port, {:data, data}} ->
        msg =
          [
            "[#{inspect(farmware)}] sent data:",
            "\r\n\=\=\=\=\=\=\=\=\=\=\=\r\n\r\n",
            data,
            "\r\n\=\=\=\=\=\=\=\=\=\=\=\r\n\r\n"
          ]
          |> Enum.join()

        # Logger.info(3, msg, color: :NC)
        IO.puts(msg)
        handle_port(state)
    end
  end

  def build_env(%Farmware{config: config, name: fw_name} = farmware, env) do
    token =
      Farmbot.System.ConfigStorage.get_config_value(
        :string,
        "authorization",
        "token"
      )

    images_dir = "/tmp/images"
    python_path = Farmbot.Farmware.Installer.install_path(farmware) <> ":"

    config
    |> Enum.filter(&match?(%{"label" => _, "name" => _, "value" => _}, &1))
    |> Map.new(&format_config(fw_name, &1))
    |> Map.put("API_TOKEN", token)
    |> Map.put("FARMWARE_TOKEN", token)
    |> Map.put("IMAGES_DIR", images_dir)
    |> Map.put("FARMWARE_URL", "http://localhost:27347/")
    |> Map.put("FARMBOT_OS_VERSION", @fbos_version)
    |> Map.put("PYTHONPATH", python_path)
    |> Map.merge(Farmbot.BotState.get_user_env())
    |> Map.merge(Map.new(env))
    |> Enum.map(fn {key, val} -> {to_erl_safe(key), to_erl_safe(val)} end)
  end

  defp format_config(fw_name, %{"label" => _, "name" => name, "value" => val}) do
    sep =
      cond do
        String.contains?(fw_name, "-") -> "-"
        String.contains?(fw_name, "_") -> "_"
        String.contains?(fw_name, " ") -> " "
        true -> nil
      end

    ns =
      if sep do
        String.split(fw_name |> Macro.underscore(), sep)
        |> Enum.join()
        |> String.downcase()
        |> Macro.underscore()
      else
        fw_name |> Macro.underscore() |> String.downcase()
      end

    {"#{ns}_#{name}", val}
  end

  defp to_erl_safe(binary) when is_binary(binary), do: to_charlist(binary)

  defp to_erl_safe(map) when is_map(map),
    do: map |> Poison.encode!() |> to_erl_safe()

  defp to_erl_safe(number) when is_number(number),
    do: "#{number}" |> to_charlist
end
