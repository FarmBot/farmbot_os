defmodule FarmbotOS.Init.FSCheckup do
  @moduledoc """
  Performs a filesystem checkup and formats the
  volume on first boot.
  """

  use Supervisor
  require Logger

  @data_path FarmbotOS.FileSystem.data_path()

  @ref FarmbotOS.Project.commit()
  @version FarmbotOS.Project.version()
  @target FarmbotOS.Project.target()
  @env FarmbotOS.Project.env()
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

        if FarmbotOS.Project.target() != :host do
          init_logger()
        end

        :ok

      err ->
        Logger.debug("Filesystem not up yet (#{inspect(err)})...")
        Process.sleep(1000)
        do_checkup()
    end
  end

  # TODO(Connor) move this somewhere else.
  # This function used to be for setting up logger_backend_sqlite.
  # It needed to be here because that lib needed filesystem to be up
  # and running. Now we just need this function to remove the `console`
  # backend because `ecto` decided it wanted to add `console` and not remove
  # it when it's done. This function needs to be called _after_ migrations are
  # Called.
  defp init_logger do
    Logger.flush()

    try do
      _ = Logger.remove_backend(:console)
    catch
      :exit, r ->
        IO.warn("Could not init logging: #{inspect(r)}", __STACKTRACE__)
    end
  end
end
