defmodule Farmbot.System.CoreStart do
  @moduledoc false
  use Supervisor

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    {:ok, _} = Application.ensure_all_started(:farmbot_core)
    Supervisor.init([], [strategy: :one_for_one])
  end
end
