defmodule Farmbot.System.Init.FSCheckup do
  @moduledoc false
  use Supervisor
  @behaviour Farmbot.System.Init
  @data_path Application.get_env(:farmbot, :data_path) || Mix.raise("Unconfigured data path.")
  use Farmbot.Logger

  @ref Mix.Project.config[:commit]
  @version Mix.Project.config[:version]
  @target Mix.Project.config[:target]
  @env Mix.env()

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
        :ok

      err ->
        Logger.busy(3, "Filesystem not up yet (#{inspect(err)})...")
        Process.sleep(1000)
        do_checkup()
    end
  end
end
