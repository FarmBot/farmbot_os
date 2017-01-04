defmodule Farmbot.Transport.Supervisor do
  @moduledoc """
    Supervises services that communicate with the outside world.
  """
  use Supervisor
  @transports Application.get_env(:farmbot, :transports)

  def init([]) do
    children = build_children(@transports)
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  @doc """
    Starts all the transports.
  """
  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  defp build_children(transports) do
    [worker(Farmbot.Transport, [], restart: :permanent)] ++
    Enum.map(transports, fn(t) ->
      worker(t, [], restart: :permanent)
    end)
  end
end
