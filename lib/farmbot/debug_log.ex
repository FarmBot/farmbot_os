defmodule Farmbot.DebugLog do
  @moduledoc """
  Provides a `debug_log/1` function.
  """

  def color(:NC),           do: "\e[0m"
  def color(:WHITE),        do: "\e[1;37m"
  def color(:BLACK),        do: "\e[0;30m"
  def color(:BLUE),         do: "\e[0;34m"
  def color(:LIGHT_BLUE),   do: "\e[1;34m"
  def color(:GREEN),        do: "\e[0;32m"
  def color(:LIGHT_GREEN),  do: "\e[1;32m"
  def color(:CYAN),         do: "\e[0;36m"
  def color(:LIGHT_CYAN),   do: "\e[1;36m"
  def color(:RED),          do: "\e[0;31m"
  def color(:LIGHT_RED),    do: "\e[1;31m"
  def color(:PURPLE),       do: "\e[0;35m"
  def color(:LIGHT_PURPLE), do: "\e[1;35m"
  def color(:BROWN),        do: "\e[0;33m"
  def color(:YELLOW),       do: "\e[1;33m"
  def color(:GRAY),         do: "\e[0;30m"
  def color(:LIGHT_GRAY),   do: "\e[0;37m"

  @doc """
    enables the `debug_log/1` function.
  """
  defmacro __using__(opts) do
    color = Keyword.get(opts, :color)
    name  = Keyword.get(opts, :name)
    quote do

      if unquote(name) do
        defp get_module, do: unquote(name)
      else
        defp get_module, do: __MODULE__ |> Module.split() |> List.last
      end

      if unquote(color) do
        defp debug_log(str) do
          GenEvent.notify(Farmbot.DebugLog,
            {get_module(), {unquote(color), str}})
        end
      else
        defp debug_log(str) do
          GenEvent.notify Farmbot.DebugLog, {Farmbot.DebugLog, {:BLUE, str}}
        end
      end # if color

    end # quote
  end # defmacro

  defmodule Handler do
    @moduledoc """
      Handler for DebugLogger
    """
    use GenEvent

    @doc false
    defdelegate color(color), to: Farmbot.DebugLog

    def init(state), do: {:ok, state}

    def handle_event(_, :all), do: {:ok, :all}

    def handle_event({module, {color, str}}, state) when is_binary(str) do
      filter_me? = Map.get(state, module)
      unless filter_me? do
        IO.puts "#{color(color)} [#{module}]#{color(:NC)} #{str}"
      end
      {:ok, state}
    end

    def handle_call({:filter, :all}, _state) do
      {:ok, :all}
    end

    def handle_call({:filter, module}, state) do
      {:ok, :ok, Map.put(state, module, :filterme)}
    end

    def handle_call({:unfilter, module}, state) do
      if state == :all do
        {:ok, :error, state}
      else
        {:ok, :ok, Map.delete(state, module)}
      end
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
