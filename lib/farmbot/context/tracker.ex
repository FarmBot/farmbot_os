defmodule Farmbot.Context.Tracker do
  @moduledoc """
    Tracks the current context.
  """

  alias Farmbot.Context

  @doc "Gets current context"
  def get_context(tracker), do: GenServer.call(tracker, :get_context)

  modules  = Context.new() |> Map.from_struct |> Map.delete(:data_stack) |> Map.keys

  for module <- modules do

    @doc "Gets the #{module} part from a context."
    def unquote(module)(tracker) when is_pid(tracker),
      do: GenServer.call(tracker, unquote(module))

  end

  @doc """
    Starts a context tracker.
  """
  def start_link(%Context{} = context, opts) do
    GenServer.start_link(__MODULE__, context, opts)
  end

  def init(context), do: {:ok, context}

  def handle_call(:get_context, _from, context), do: {:reply, context, context}

  for module <- modules do

    def handle_call(unquote(module), _from, context),
      do: {:reply, context[unquote(module)], context}

  end
end
