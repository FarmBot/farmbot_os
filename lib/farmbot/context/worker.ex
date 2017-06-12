defmodule Farmbot.Context.Worker do
  @moduledoc """
    Helper macro for worker modules concerned with context.
  """

  defmacro __using__(_) do
    quote do
      use Farmbot.DebugLog,
        name: __MODULE__ |> Module.split() |> Enum.take(-2) |> Enum.join
      use GenServer
      alias Farmbot.Context

      @doc "Start a #{__MODULE__} worker"
      def start_link(%Context{} = ctx, opts) do
        debug_log "Starting worker: #{__MODULE__} with #{inspect opts}"
        GenServer.start_link(__MODULE__, ctx, opts)
      end

      def init(ctx), do: {:ok, %{context: ctx}}

      defoverridable([init: 1])
    end
  end
end
