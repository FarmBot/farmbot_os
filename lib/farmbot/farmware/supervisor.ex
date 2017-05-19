defmodule Farmware.Supervisor do
  @moduledoc """
    Supervises Farmware
  """

  require Logger
  alias Farmbot.System.FS
  alias Farmbot.Context
  use Supervisor

  @doc """
    Starts the Farmware Supervisor
  """
  def start_link(%Context{} = ctx, opts),
    do: Supervisor.start_link(__MODULE__, ctx, opts)

  def init(context) do
    # create the farmware folder if it doesnt exist.
    check_dir()

    # register the available farmwares in the ProcessTracker
    register_farmwares(context)

    children = [
      worker(Farmware.Tracker, [context, [name: Farmware.Tracker]])
    ]

    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  @spec register_farmwares(Context.t) :: no_return
  defp register_farmwares(%Context{} = ctx) do
    farmwares = File.ls!(FS.path() <> "/farmware")
    for farmware <- farmwares do
      Farmbot.BotState.ProcessTracker.register(ctx.process_tracker, :farmware, farmware, farmware)
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
