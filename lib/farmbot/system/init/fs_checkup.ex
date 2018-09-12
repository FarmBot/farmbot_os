defmodule Farmbot.System.Init.FSCheckup do
  @moduledoc false
  use Supervisor
  use Farmbot.Logger

  @behaviour Farmbot.System.Init
  @data_path Application.get_env(:farmbot, :data_path)
  @data_path || Mix.raise("Unconfigured data path.")

  @ref Farmbot.Project.commit()
  @version Farmbot.Project.version()
  @target Farmbot.Project.target()
  @env Farmbot.Project.env()

  @doc false
  def start_link(_, opts \\ []) do
    Supervisor.start_link(__MODULE__, [], opts)
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

    setup_multi_user()

    Logger.busy(3, "Checking #{check_file}")
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
          Logger.busy(3, "Deleting: #{fw}")
          File.rm_rf(fw)
        end
        init_logger_backend_ecto()
        :ok

      err ->
        Logger.busy(3, "Filesystem not up yet (#{inspect(err)})...")
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
    try do
      Elixir.Logger.add_backend(LoggerBackendSqlite)
    catch
      :exit, _ -> Logger.error 1, "Could not start disk logging."
    end
  end
end
