defmodule Farmbot.System.Supervisor do
  @moduledoc """
  Supervises Platform specific stuff for Farmbot to operate
  """
  use    Supervisor
  alias  Farmbot.System.Init
  import Init


  error_msg = """
  Please configure your environment's init system!
  """

  @children Application.get_env(:farmbot, :init) || Mix.raise(error_msg)

  @doc "Start the System Services. This is more or less `init`."
  def start_link(args, opts \\ []) do
    Supervisor.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    @children
    |> Enum.map(fn(child) -> fb_init(child, [args, [name: child]]) end)
    |> supervise([strategy: :one_for_all])
  end
end
