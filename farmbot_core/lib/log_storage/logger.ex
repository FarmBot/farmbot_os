defmodule Farmbot.Logger do
  @moduledoc """
  Log messages to Farmot endpoints.
  """

  alias Farmbot.Logger.Repo

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

  def insert_log!(%Farmbot.Log{} = log) do
    Farmbot.Log.changeset(log, %{})
    |> Repo.insert!()
  end

  @doc "Gets a log by it's id, deletes it."
  def handle_log(id) do
    case Repo.get(Farmbot.Log, id) do
      %Farmbot.Log{} = log -> Repo.delete!(log)
      nil -> nil
    end
  end

  @doc "Gets all available logs and deletes them."
  def handle_all_logs do
    Repo.all(Farmbot.Log)
    |> Enum.map(&Repo.delete!(&1))
  end

  @doc false
  def dispatch_log(%Macro.Env{} = env, level, verbosity, message, meta)
  when level in [:info, :debug, :busy, :warn, :success, :error, :fun]
  and  is_number(verbosity)
  and  is_binary(message)
  and  is_list(meta)
  do
    fun = case env.function do
      {fun, ar} -> "#{fun}/#{ar}"
      nil -> "no_function"
    end

    struct(Farmbot.Log, [
      level: level,
      verbosity: verbosity,
      message: message,
      meta: Map.new(meta),
      function: fun,
      file: env.file,
      line: env.line,
      module: env.module])
    |> dispatch_log()
  end

  @doc false
  def dispatch_log(%Farmbot.Log{} = log) do
    log
    |> insert_log!()
    |> elixir_log()
    |> fn(log) ->
      Farmbot.Registry.dispatch(__MODULE__, {:log_ready, log.id})
    end.()
  end

  defp elixir_log(%Farmbot.Log{} = log) do
    # TODO Connor - fix time
    logger_meta = [
      application: :farmbot,
      function: log.function,
      file: log.file,
      line: log.line,
      module: log.module,
      # time: time
    ]
    level = log.level
    logger_level = if level in [:info, :debug, :warn, :error], do: level, else: :info
    Elixir.Logger.bare_log(logger_level, log, logger_meta)
    log
  end

  @doc "Helper function for deciding if a message should be logged or not."
  def should_log?(module, verbosity)
  def should_log?(nil, verbosity) when verbosity <= 3, do: true
  def should_log?(nil, _), do: false

  def should_log?(module, verbosity) when verbosity <= 3 do
    List.first(Module.split(module))  == "Farmbot"
  end

  def should_log?(_, _), do: false
end
