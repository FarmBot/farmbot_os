defmodule FarmbotOS.Platform.Target.NervesHubClient do
  @moduledoc """
  Client that decides when an update should be done.
  """

  use GenServer
  require FarmbotCore.Logger
  alias FarmbotCore.{Asset, BotState, BotState.JobProgress.Percent, Project}

  @behaviour NervesHub.Client
  @behaviour FarmbotOS.NervesHub

  @current_version Project.version()
  @data_path FarmbotOS.FileSystem.data_path()
  @data_path || Mix.raise("Please configure data_path in application env")

  def serial_number(:rpi0), do: serial_number("rpi")
  def serial_number(:rpi3), do: serial_number("rpi")

  def serial_number(plat) do
    :os.cmd(
      '/usr/bin/boardid -b uboot_env -u nerves_serial_number -b uboot_env -u serial_number -b #{
        plat
      }'
    )
    |> to_string()
    |> String.trim()
  end

  def uuid, do: Nerves.Runtime.KV.get_active("nerves_fw_uuid")

  def serial_number, do: serial_number(Project.target())

  def connect do
    config = config()

    if nil in config do
      {:error, "No OTA Certs: #{inspect(config)}"}
    else
      FarmbotCore.Logger.debug(3, "Starting OTA Service")
      # NervesHub replaces it's own env on startup. Reset it.

      supervisor = FarmbotOS
      # Stop Nerves Hub if it is running.
      _ = Supervisor.terminate_child(supervisor, NervesHub.Supervisor)
      _ = Supervisor.delete_child(supervisor, NervesHub.Supervisor)

      # Cause NervesRuntime.KV to restart.
      _ = GenServer.stop(Nerves.Runtime.KV)

      # Wait for a few seconds for good luck.
      Process.sleep(1000)

      # Start the connection again.
      {:ok, _pid} = Supervisor.start_child(supervisor, NervesHub.Supervisor)
      FarmbotCore.Logger.debug(3, "OTA Service started")
      :ok
    end
  end

  def provision(serial) do
    Nerves.Runtime.KV.UBootEnv.put("nerves_serial_number", serial)
    Nerves.Runtime.KV.UBootEnv.put("nerves_fw_serial_number", serial)
  end

  def configure_certs(cert, key) do
    Nerves.Runtime.KV.UBootEnv.put("nerves_hub_cert", cert) |> IO.inspect()
    Nerves.Runtime.KV.UBootEnv.put("nerves_hub_key", key) |> IO.inspect()
    :ok
  end

  def deconfigure() do
    Nerves.Runtime.KV.UBootEnv.put("nerves_hub_cert", "")
    Nerves.Runtime.KV.UBootEnv.put("nerves_hub_key", "")
    Nerves.Runtime.KV.UBootEnv.put("nerves_serial_number", "")
    Nerves.Runtime.KV.UBootEnv.put("nerves_fw_serial_number", "")
    :ok
  end

  def config() do
    [
      Nerves.Runtime.KV.get("nerves_fw_serial_number"),
      Nerves.Runtime.KV.get("nerves_hub_cert"),
      Nerves.Runtime.KV.get("nerves_hub_key")
    ]
    |> Enum.map(fn val ->
      if val == "", do: nil, else: val
    end)
  end

  def check_update do
    case GenServer.call(__MODULE__, :check_update) do
      # If updates were disabled, and an update is queued
      {:ignore, _url} ->
        FarmbotCore.Logger.info(1, "Applying OTA update")
        NervesHub.update()

      _ ->
        FarmbotCore.Logger.debug(1, "No update cached. Checking for tag changes.")

        case NervesHub.HTTPClient.update() do
          {:ok, %{"data" => %{"update_available" => false}}} ->
            nil

          _ ->
            FarmbotCore.Logger.info(1, "Applying OTA update")
            NervesHub.update()
        end
    end
  end

  # Callback for NervesHub.Client
  def update_available(args) do
    GenServer.call(__MODULE__, {:update_available, args}, :infinity)
  end

  def handle_error(args) do
    FarmbotCore.Logger.error(1, "OTA failed to download: #{inspect(args)}")
    prog = %Percent{status: "error"}

    if Process.whereis(BotState) do
      BotState.set_job_progress("FBOS_OTA", prog)
    end

    :ok
  end

  def handle_fwup_message({:ok, _, _info}) do
    FarmbotCore.Logger.success(1, "OTA Complete Going down for reboot")
    prog = %Percent{percent: 100, status: "complete"}

    if Process.whereis(BotState) do
      BotState.set_job_progress("FBOS_OTA", prog)
    end

    :ok
  end

  def handle_fwup_message({:progress, 100}) do
    FarmbotCore.Logger.success(1, "OTA Complete. Going down for reboot")
    prog = %Percent{percent: 100, status: "complete"}

    if Process.whereis(BotState) do
      BotState.set_job_progress("FBOS_OTA", prog)
    end

    :ok
  end

  def handle_fwup_message({:progress, percent}) when rem(percent, 5) == 0 do
    prog = %Percent{percent: percent}

    if Process.whereis(BotState) do
      BotState.set_job_progress("FBOS_OTA", prog)
    end

    :ok
  end

  def handle_fwup_message({:error, _, reason}) do
    FarmbotCore.Logger.error(1, "OTA failed to apply: #{inspect(reason)}")
    prog = %Percent{status: :error}

    if Process.whereis(BotState) do
      BotState.set_job_progress("FBOS_OTA", prog)
    end

    :ok
  end

  def handle_fwup_message(_) do
    :ok
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    maybe_post_update()
    {:ok, nil}
  end

  def handle_call({:update_available, %{"firmware_url" => url}}, _, _state) do
    if Process.whereis(BotState) do
      BotState.set_update_available(true)
    end

    case Asset.fbos_config(:os_auto_update) do
      true ->
        FarmbotCore.Logger.success(1, "Applying OTA update")
        {:reply, :apply, {:apply, url}}

      false ->
        FarmbotCore.Logger.info(1, "New Farmbot OS is available!")
        {:reply, :ignore, {:ignore, url}}
    end
  end

  def handle_call(:check_update, _from, state) do
    {:reply, state, state}
  end

  defp maybe_post_update do
    case File.read(update_file()) do
      {:ok, @current_version} ->
        :ok

      {:ok, old_version} ->
        FarmbotCore.Logger.info(
          1,
          "Updating FarmbotOS from #{old_version} to #{@current_version}"
        )

        do_post_update()

      {:error, :enoent} ->
        FarmbotCore.Logger.info(1, "Setting up FarmbotOS #{@current_version}")

      {:error, err} ->
        raise err
    end

    before_update()
  end

  defp do_post_update do
    IO.warn("flash firmware at this point i guess?")
    File.rm(update_file())
  end

  defp before_update, do: File.write!(update_file(), @current_version)

  defp update_file, do: Path.join(@data_path, "update")
end
