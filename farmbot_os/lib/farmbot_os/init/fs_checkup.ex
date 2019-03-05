defmodule FarmbotOS.Init.FSCheckup do
  @moduledoc false
  use Supervisor
  require Logger

  @data_path FarmbotOS.FileSystem.data_path()

  @ref FarmbotCore.Project.commit()
  @version FarmbotCore.Project.version()
  @target FarmbotCore.Project.target()
  @env FarmbotCore.Project.env()
  System.put_env("NERVES_FW_VCS_IDENTIFIER", @ref)

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc false
  def init([]) do
    do_checkup()
    :ignore
  end

  defp do_checkup do
    check_file = Path.join(@data_path, "boot")

    unless File.exists?(@data_path) do
      File.mkdir(@data_path)
    end

    Logger.debug("Checking #{check_file}")

    msg = """
    version = #{@version}
    commit  = #{@ref}
    target  = #{@target}
    env     = #{@env}
    """

    case File.write(check_file, msg) do
      :ok ->
        Process.sleep(500)

        for fw <- Path.wildcard(Path.join(@data_path, "*.fw")) do
          Logger.debug("Deleting: #{fw}")
          File.rm_rf(fw)
        end

        init_logger_backend_ecto()
        :ok

      err ->
        Logger.debug("Filesystem not up yet (#{inspect(err)})...")
        Process.sleep(1000)
        do_checkup()
    end
  end

  defp init_logger_backend_ecto do
    Logger.flush()

    try do
      Logger.add_backend(LoggerBackendSqlite)
    catch
      :exit, r ->
        Logger.error("Could not start disk logging: #{inspect(r)}")
        Logger.remove_backend(LoggerBackendSqlite)
        File.rm(Path.join([@data_path, "root", "debug_logs.sqlite3"]))
    end
  end
end
