defmodule FarmbotOS.Platform.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    platform_children = Application.get_env(:farmbot, __MODULE__)[:platform_children]
    Supervisor.init(platform_children, strategy: :one_for_all)
  end
end
