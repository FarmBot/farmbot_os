defmodule Farmbot.BotState.Transport.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    transports = Application.get_env(:farmbot, :transport)
    children = Enum.reduce(transports, [], fn(t, acc) ->
      if Code.ensure_loaded?(t) do
        acc ++ [worker(t, [])]
      else
        acc
      end
    end)
    supervise(children, strategy: :one_for_one)
  end
end
