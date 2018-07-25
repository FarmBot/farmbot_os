defmodule Farmbot.System.Init.FSCheckup do
  @moduledoc false
  use Supervisor
  require Logger

  @data_path Application.get_env(:farmbot_ext, :data_path)
  @data_path || Mix.raise("Unconfigured data path.")

  @ref Farmbot.Project.commit()
  @version Farmbot.Project.version()
  @target Farmbot.Project.target()
  @env Farmbot.Project.env()
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

    setup_boot_state_file()
    setup_multi_user()

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

  defp setup_multi_user do
    multiuser_dir = Path.join([@data_path, "users", "default"])
    unless File.exists?(multiuser_dir) do
      File.mkdir_p(multiuser_dir)
    end
  end

  defp init_logger_backend_ecto do
    Logger.flush()
    try do
      Logger.add_backend(LoggerBackendSqlite)
    catch
      :exit, r ->
        Logger.error "Could not start disk logging: #{inspect r}"
        Logger.remove_backend(LoggerBackendSqlite)
        File.rm(Path.join([@data_path, "root", "debug_logs.sqlite3"]))
    end
  end

  defp setup_boot_state_file do
    file = Path.join(@data_path, "boot_state")
    unless File.exists?(file) do
      Farmbot.BootState.write(:NEEDS_CONFIGURATION)
    end
  end
end
