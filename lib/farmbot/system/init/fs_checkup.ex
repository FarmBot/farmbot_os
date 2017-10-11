defmodule Farmbot.System.Init.FSCheckup do
  @moduledoc "Init module for bringup and teardown of ecto."
  use Supervisor
  @behaviour Farmbot.System.Init
  @data_path Application.get_env(:farmbot, :data_path) || Mix.raise("Unconfigured data path.")
  require Logger

  @doc "This will run migrations on all Farmbot Repos."
  def start_link(_, opts \\ []) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    do_checkup()
    :ignore
  end

  defp do_checkup do
    check_file = Path.join(@data_path, "boot")

    unless File.exists?(@data_path) do
      File.mkdir(@data_path)
    end

    Logger.info("Checking #{check_file}")

    case File.write(check_file, "Hello") do
      :ok ->
        Process.sleep(500)
        :ok

      err ->
        Logger.info("Filesystem not up yet (#{inspect(err)})...")
        Process.sleep(1000)
        do_checkup()
    end
  end
end
