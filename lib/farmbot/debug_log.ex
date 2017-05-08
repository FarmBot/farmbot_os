defmodule Farmbot.DebugLog do
  @moduledoc """
  Provides a `debug_log/1` function.
  """

  @doc """
    enables the `debug_log/1` function.
  """
  defmacro __using__(_opts) do
    quote do
      def debug_log(str), do: GenEvent.notify Farmbot.DebugLog, {__MODULE__, str}
    end # quote
  end # defmacro

  defmodule Handler do
    @moduledoc """
      Handler for DebugLogger
    """
    use GenEvent

    def init(state), do: {:ok, state}

    def handle_event({module, str}, state) when is_binary(str) do
      unless Map.get(state, module) do
        IO.puts "[#{module}] #{str}"
      end
      {:ok, state}
    end

    def handle_call({:filter, module}, state) do
      {:ok, :ok, Map.put(state, module, :filterme)}
    end

    def handle_call({:unfilter, module}, state) do
      {:ok, :ok, Map.delete(state, module)}
    end
  end

  @doc """
    Start the Debug Logger
  """
  def start_link do
    {:ok, pid} = GenEvent.start_link(name: __MODULE__)
    :ok = GenEvent.add_handler(pid, Handler, %{})
    {:ok, pid}
  end

  @doc """
    Filter a module from the handler.
  """
  def filter(module) do
    GenEvent.call(__MODULE__, Handler, {:filter, module})
  end

  @doc """
    Unfilter a module from the handler.
  """
  def unfilter(module) do
    GenEvent.call(__MODULE__, Handler, {:unfilter, module})
  end
end # defmodule
