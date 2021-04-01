defmodule FarmbotCore.Logger do
  @moduledoc """
  Log messages to Farmot endpoints.
  """

  require Logger
  alias FarmbotCore.{Log, Logger.Repo}
  import Ecto.Query
  @log_types [:info, :debug, :busy, :warn, :success, :error, :fun, :assertion]

  @doc "Send a debug message to log endpoints"
  defmacro debug(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      FarmbotCore.Logger.dispatch_log(__ENV__, :debug, verbosity, message, meta)
    end
  end

  @doc "Send an info message to log endpoints"
  defmacro info(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      FarmbotCore.Logger.dispatch_log(__ENV__, :info, verbosity, message, meta)
    end
  end

  @doc "Send an busy message to log endpoints"
  defmacro busy(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      FarmbotCore.Logger.dispatch_log(__ENV__, :busy, verbosity, message, meta)
    end
  end

  @doc "Send an success message to log endpoints"
  defmacro success(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      FarmbotCore.Logger.dispatch_log(__ENV__, :success, verbosity, message, meta)
    end
  end

  @doc "Send an warn message to log endpoints"
  defmacro warn(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      FarmbotCore.Logger.dispatch_log(__ENV__, :warn, verbosity, message, meta)
    end
  end

  @doc "Send an error message to log endpoints"
  defmacro error(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      FarmbotCore.Logger.dispatch_log(__ENV__, :error, verbosity, message, meta)
    end
  end

  @doc false
  defmacro fun(verbosity, message, meta \\ []) do
    quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
      FarmbotCore.Logger.dispatch_log(__ENV__, :fun, verbosity, message, meta)
    end
  end

  def insert_log!(%{ message: _, level: _, verbosity: _ } = input) do
    params = input |> Map.delete(:__meta__) |> Map.delete(:__struct__)
    changeset = Log.changeset(%Log{}, params)

    try do
      maybe_truncate_logs!()
      message = Ecto.Changeset.get_field(changeset, :message)

      case Repo.get_by(Log, message: message) do
        nil ->
          Repo.insert!(changeset)

        old ->
          params =
            params
            |> Map.put(:inserted_at, DateTime.utc_now())
            |> Map.put(:duplicates, old.duplicates + 1)

          old
          |> Log.changeset(params)
          |> Repo.update!()
      end
    catch
      kind, err ->
        IO.warn("Error inserting log: #{kind} #{inspect(err)}", __STACKTRACE__)
        Ecto.Changeset.apply_changes(changeset)
    end
  end

  def insert_log!(other) do
    Logger.error("Can't decode log: #{inspect(other)}")
  end

  @doc "Gets a log by it's id, deletes it."
  def handle_log(id) do
    case Repo.get(FarmbotCore.Log, id) do
      %Log{} = log -> Repo.delete!(log)
      nil -> nil
    end
  end

  @doc "Gets all available logs and deletes them."
  def handle_all_logs do
    Repo.all(from(l in FarmbotCore.Log, order_by: l.inserted_at))
    |> Enum.map(&Repo.delete!/1)
  end

  @doc false
  def dispatch_log(%Macro.Env{} = env, level, verbosity, message, meta)
      when level in @log_types and
             is_number(verbosity) and
             is_binary(message) and
             is_list(meta) do
    fun =
      case env.function do
        {fun, ar} -> "#{fun}/#{ar}"
        nil -> "no_function"
      end

    %{
      level: level,
      verbosity: verbosity,
      message: message,
      meta: Map.new(meta),
      function: fun,
      file: env.file,
      line: env.line,
      module: env.module
    }
    |> dispatch_log()
  end

  @doc false
  def dispatch_log(params) do
    log = insert_log!(params)
    FarmbotCore.LogExecutor.execute(log)
  end

  @doc "Helper function for deciding if a message should be logged or not."
  def should_log?(module, verbosity)
  def should_log?(nil, verbosity) when verbosity <= 3, do: true
  def should_log?(nil, _), do: false

  def should_log?(module, verbosity) when verbosity <= 3 do
    List.first(Module.split(module)) =~ "Farmbot"
  end

  def should_log?(_, _), do: false

  # Under rare circumstances, it is possible for logs to fill
  # to the point that SQLite cannot add any more.
  # For these very rare cases, we naively drop all logs under
  # the assumption that there is a very serious problem.
  def maybe_truncate_logs!(limit \\ 1000) do
    count = Repo.one(from l in "logs", select: count(l.id))
    if count > limit do
      Repo.delete_all(Log)
    end
  end
end
