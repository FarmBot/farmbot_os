defmodule Farmbot do
  @moduledoc """
  Supervises the individual modules that make up the Farmbot Application.
  This is the entry point of the application.
  """
  require Farmbot.Logger
  require Logger
  use Application

  @version Farmbot.Project.version()
  @commit Farmbot.Project.commit()

  @doc false
  def start(type, start_opts)

  def start(_, _start_opts) do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    children = [
      {Farmbot.System.Registry, []},
      {Farmbot.Logger.Supervisor, []},
      {Farmbot.System.Supervisor, []},
      {Farmbot.Bootstrap.Supervisor, []}
    ]

    Farmbot.Logger.info(1, "Booting Farmbot OS version: #{@version} - #{@commit}")
    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
