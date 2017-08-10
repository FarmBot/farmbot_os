defmodule Farmbot.System.Supervisor do
  @moduledoc """
  Supervises Platform specific stuff for Farmbot to operate
  """
  use    Supervisor
  import Farmbot.System.Init

  error_msg = """
  Please configure your environment's init system!
  """

  @children Application.get_env(:farmbot, :init) || Mix.raise(error_msg)

  @doc "Start the System Services. This is more or less `init`."
  def start_link(args, opts \\ []) do
    Supervisor.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    children = Enum.map(@children, fn(child) ->
      fb_init(child, [args, [name: child]])
    end)
    opts = [strategy: :one_for_all]
    supervise(children, opts)
  end
end
