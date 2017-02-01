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
    children = [worker(Farmware.Tracker, [])]
    opts = [strategy: :one_for_one, name: Farmware.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @spec check_dir :: no_return
  defp check_dir do
    path = FS.path() <> "/farmware"
    unless File.exists?(path) do
      Logger.debug ">> creating farmware dir."
      FS.transaction fn() ->
        File.mkdir(path)
      end
    end
  end
end
