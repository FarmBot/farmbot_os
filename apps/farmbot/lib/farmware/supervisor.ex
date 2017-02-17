defmodule Farmware.Supervisor do
  @moduledoc false
  require Logger
  alias Farmbot.System.FS

  @doc """
    Starts the Farmware Supervisor
  """
  @spec start_link :: {:ok, pid}
  def start_link do
    import Supervisor.Spec, warn: false
    # create the farmware folder if it doesnt exist.
    check_dir()
    # register the available farmwares in the ProcessTracker
    register_farmwares()
    children = [worker(Farmware.Tracker, [])]
    opts = [strategy: :one_for_one, name: Farmware.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @spec register_farmwares :: no_return
  defp register_farmwares do
    farmwares = File.ls!(FS.path() <> "/farmware")
    for farmware <- farmwares do
      Farmbot.BotState.ProcessTracker.register(:farmware, farmware, farmware)
    end
  end

  @spec check_dir :: no_return
  defp check_dir do
    path = FS.path() <> "/farmware"
    unless File.exists?(path) do
      Logger.info ">> creating farmware dir."
      FS.transaction fn() ->
        File.mkdir(path)
      end, true
    end
  end
end
