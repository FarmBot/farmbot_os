defmodule Farmbot do
  @moduledoc """
  Supervises the individual modules that make up the Farmbot Application.
  This is the entry point of the application.
  """

  require Farmbot.Logger
  require Logger
  use Supervisor

  @version Farmbot.Project.version()
  @commit Farmbot.Project.commit()

  @doc false
  def start(type, start_opts)

  def start(_, _start_opts) do
    case Supervisor.start_link(__MODULE__, [], [name: __MODULE__]) do
      {:ok, pid} -> {:ok, pid}
      error ->
        IO.puts "Failed to boot Farmbot: #{inspect error}"
        Farmbot.System.factory_reset(error)
        exit(error)
    end
  end

  def init([]) do
    Logger.remove_backend :console
    RingLogger.attach()
    children = [
      supervisor(Farmbot.Logger.Supervisor, []),
      supervisor(Farmbot.System.Supervisor, []),
      supervisor(Farmbot.Bootstrap.Supervisor, [])
    ]

    Farmbot.Logger.info(1, "Booting Farmbot OS version: #{@version} - #{@commit}")
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
