defmodule Farmbot.Context.Tracker do
  @moduledoc """
    Tracks the current context.
  """


  alias Farmbot.Context
  use GenServer

  defstruct [:pid]

  defimpl Inspect, for: __MODULE__ do
    def inspect(%{pid: pid}, _) when is_pid(pid) do
      "#PID<" <> rest = inspect pid
      info = String.trim(rest, ">")
      "#ContextTracker<#{info}>"
    end

    def inspect(_, _), do: "#ContextTracker<:invalid>"
  end

  @doc "Gets current context"
  def get_context(tracker), do: GenServer.call(tracker, :get_context)

  modules =
    Context.new()
    |> Map.from_struct
    |> Enum.filter(fn({_key, val}) -> is_atom(val) end)
    |> Enum.map(fn({k, _}) -> k end)

  def modules, do: unquote(modules)

  for module <- modules do

    @doc "Gets the #{module} part from a context."
    def unquote(module)(tracker) when is_pid(tracker),
      do: GenServer.call(tracker, unquote(module))

    def unquote(module)(%__MODULE__{pid: tracker}) when is_pid(tracker),
      do: GenServer.call(tracker, unquote(module))

    @doc "Updates a #{module}'s pid or name."
    def update(%__MODULE__{pid: tracker}, mod, value) when is_pid(tracker),
      do: update(tracker, mod, value)

    def update(tracker, unquote(module) = mod, value)
    when is_pid(tracker)
    and is_atom(mod)
    and (is_atom(value) or is_pid(value))
    do
      GenServer.call(tracker, {:update, unquote(module), value})
    end
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

    def handle_call({:update, unquote(module), value}, _from, context) do
      {:reply, :ok, %{context | unquote(module) => value}}
    end
  end

  def handle_call(_, _, context) do
    {:reply, :error, context}
  end
end
