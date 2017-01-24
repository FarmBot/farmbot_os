defmodule Farmware.Application do
  @moduledoc false

  require Logger
  use Application
  alias Farmbot.System.FS

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    # create the farmware folder if it doesnt exist.
    check_dir()
    children = [worker(Farmware.Tracker, [])]
    opts = [strategy: :one_for_one, name: Farmware.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp check_dir() do
    path = FS.path() <> "/farmware"
    if !File.exists?(path) do
      Logger.debug ">> creating farmware dir."
      FS.transaction fn() ->
        File.mkdir(path)
      end
    else
      Logger.debug ">> farmware dir already exists."
    end
  end
end
