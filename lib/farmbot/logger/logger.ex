defmodule Farmbot.Logger do
  @moduledoc "Logger."
  use GenStage

  defmacro debug(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      Farmbot.Logger.dispatch_log(__ENV__, :debug, verbosity, message, meta)
    end
  end

  defmacro info(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      Farmbot.Logger.dispatch_log(__ENV__, :info, verbosity, message, meta)
    end
  end

  defmacro busy(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      Farmbot.Logger.dispatch_log(__ENV__, :budy, verbosity, message, meta)
    end
  end

  defmacro success(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      Farmbot.Logger.dispatch_log(__ENV__, :success, verbosity, message, meta)
    end
  end

  defmacro warn(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      Farmbot.Logger.dispatch_log(__ENV__, :warn, verbosity, message, meta)
    end
  end

  defmacro error(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      Farmbot.Logger.dispatch_log(__ENV__, :error, verbosity, message, meta)
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
      ]

    end
  end

  @doc false
  def dispatch_log(env, level, verbosity, message, meta) do
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
    Elixir.Logger.add_backend(Elixir.Logger.Backends.Farmbot, [])
    {:producer, %{}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_demand(_, state) do
    {:noreply, [], state}
  end

  def handle_events(_, _from, state) do
    {:noreply, [], state}
  end

  def handle_cast({:dispatch_log, {env, level, verbosity, message, meta}}, state) do
    time = :os.system_time()
    fun = case env.function do
      {fun, ar} -> "#{fun}/#{ar}"
      nil -> "no_function"
    end
    log = struct(Farmbot.Log, [
      time: time,
      level: level,
      verbosity: verbosity,
      message: message,
      meta: meta,
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
    Elixir.Logger.remove_backend(Elixir.Logger.Backends.Farmbot)
  end
end
