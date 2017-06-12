defmodule Farmbot.Context.Supervisor do
  @moduledoc """
    Helpful macros for a supervisor that uses a Context object.
  """
  alias Farmbot.Context

  defmacro __using__(_) do
    quote do
      use Farmbot.DebugLog,
        name: __MODULE__ |> Module.split() |> Enum.take(-2) |> Enum.join
      alias Farmbot.Context
      use Supervisor

      @doc "Start a #{__MODULE__} Supervisor"
      def start_link(%Context{} = ctx, opts) do
        debug_log "Starting supervisor"
        Supervisor.start_link(__MODULE__, ctx, opts)
      end

      def init(%Context{} = _ctx) do
        children = []
        opts = [strategy: :one_for_one]
        supervise(children, opts)
      end

      defoverridable([init: 1])
    end
  end
end
