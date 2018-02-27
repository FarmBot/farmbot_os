defmodule Farmbot.Logger do
  @moduledoc """
  Log messages to Farmot endpoints.
  """
  use GenStage

  @doc "Send a debug message to log endpoints"
  defmacro debug(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      Farmbot.Logger.dispatch_log(__ENV__, :debug, verbosity, message, meta)
    end
  end

  @doc "Send an info message to log endpoints"
  defmacro info(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      Farmbot.Logger.dispatch_log(__ENV__, :info, verbosity, message, meta)
    end
  end

  @doc "Send an busy message to log endpoints"
  defmacro busy(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      Farmbot.Logger.dispatch_log(__ENV__, :busy, verbosity, message, meta)
    end
  end

  @doc "Send an success message to log endpoints"
  defmacro success(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      Farmbot.Logger.dispatch_log(__ENV__, :success, verbosity, message, meta)
    end
  end

  @doc "Send an warn message to log endpoints"
  defmacro warn(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      Farmbot.Logger.dispatch_log(__ENV__, :warn, verbosity, message, meta)
    end
  end

  @doc "Send an error message to log endpoints"
  defmacro error(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      Farmbot.Logger.dispatch_log(__ENV__, :error, verbosity, message, meta)
    end
  end

  @doc false
  defmacro fun(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      Farmbot.Logger.dispatch_log(__ENV__, :fun, verbosity, message, meta)
    end
  end

  @doc false
  defmacro __using__(_) do
    quote do
      alias Farmbot.Logger
      import Farmbot.Logger, only: [
        debug: 3,
        debug: 2,
        info: 3,
        info: 2,
        busy: 3,
        busy: 2,
        success: 3,
        success: 2,
        warn: 3,
        warn: 2,
        error: 3,
        error: 2,
        fun: 2,
        fun: 3
      ]

    end
  end

  @doc false
  def dispatch_log(%Macro.Env{} = env, level, verbosity, message, meta)
  when level in [:info, :debug, :busy, :warn, :success, :error, :fun]
  and  is_number(verbosity)
  and  is_binary(message)
  and  is_list(meta)
  do
    GenStage.cast(__MODULE__, {:dispatch_log, {env, level, verbosity, message, meta}})
  end

  def dispatch_log(%Farmbot.Log{} = log) do
    GenStage.cast(__MODULE__, {:dispatch_log, log})
  end

  @doc false
  def start_link() do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    backends = Application.get_env(:farmbot, :logger)[:backends] || []
    for b <- backends do
      Elixir.Logger.add_backend(b, [])
    end
    espeak = System.find_executable("espeak")
    {:producer, %{espeak: espeak}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_demand(_, state) do
    {:noreply, [], state}
  end

  def handle_events(_, _from, state) do
    {:noreply, [], state}
  end

  def handle_cast({:dispatch_log, {env, level, verbosity, message, meta}}, state) do
    time = :os.system_time(:seconds)
    fun = case env.function do
      {fun, ar} -> "#{fun}/#{ar}"
      nil -> "no_function"
    end
    meta_map = Map.new(meta)
    maybe_espeak(message, Map.get(meta_map, :channels, []), state.espeak)
    log = struct(Farmbot.Log, [
      time: time,
      level: level,
      verbosity: verbosity,
      message: message,
      meta: meta_map,
      function: fun,
      file: env.file,
      line: env.line,
      module: env.module])
    {:noreply, [log], state}
  end

  def handle_cast({:dispatch_log, %Farmbot.Log{} = log}, state) do
    {:noreply, [log], state}
  end

  def terminate(_, _state) do
    backends = Application.get_env(:farmbot, :logger)[:backends] || []
    for b <- backends do
      Elixir.Logger.remove_backend(b, [])
    end
  end

  defp maybe_espeak(_message, _channels, nil), do: :ok
  defp maybe_espeak(message, channels, exe) do
    if Enum.find(channels, fn(ch) -> (ch == :espeak) || (ch == "espeak") end) do
      spawn System, :cmd, [exe, [message]]
    end
    :ok
  end
end
