defmodule FarmbotOS.Logger do
  @moduledoc """
  Log messages to Farmbot endpoints.
  """

  require Logger
  alias FarmbotOS.{Log, Asset.Repo}
  import Ecto.Query
  @log_types [:info, :debug, :busy, :warn, :success, :error, :fun, :assertion]

  @doc "Send a debug message to log endpoints"
  def debug(verbosity, message, meta \\ []) do
    # quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
    FarmbotOS.Logger.dispatch_log(:debug, verbosity, message, meta)
    # end
  end

  @doc "Send an info message to log endpoints"
  def info(verbosity, message, meta \\ []) do
    # quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
    FarmbotOS.Logger.dispatch_log(:info, verbosity, message, meta)
    # end
  end

  @doc "Send an busy message to log endpoints"
  def busy(verbosity, message, meta \\ []) do
    # quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
    FarmbotOS.Logger.dispatch_log(:busy, verbosity, message, meta)
    # end
  end

  @doc "Send an success message to log endpoints"
  def success(verbosity, message, meta \\ []) do
    # quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
    FarmbotOS.Logger.dispatch_log(:success, verbosity, message, meta)
    # end
  end

  @doc "Send an warn message to log endpoints"
  def warn(verbosity, message, meta \\ []) do
    # quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
    FarmbotOS.Logger.dispatch_log(:warn, verbosity, message, meta)
    # end
  end

  @doc "Send an error message to log endpoints"
  def error(verbosity, message, meta \\ []) do
    # quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
    FarmbotOS.Logger.dispatch_log(:error, verbosity, message, meta)
    # end
  end

  @doc false
  def fun(verbosity, message, meta \\ []) do
    # quote bind_quoted: [verbosity: verbosity, message: message, meta: meta] do
    FarmbotOS.Logger.dispatch_log(:fun, verbosity, message, meta)
    # end
  end

  defmacro report_termination() do
    quote do
      def terminate(:normal, _state), do: nil

      def terminate(reason, _state) do
        mod = inspect(__MODULE__)
        err = inspect(reason)
        msg = "#{mod} termination: #{err}"
        FarmbotOS.Logger.info(3, msg)
      end
    end
  end

  def insert_log!(%{message: _, level: _, verbosity: _} = input) do
    params = input |> Map.delete(:__meta__) |> Map.delete(:__struct__)
    changeset = Log.changeset(%Log{}, params)

    try do
      maybe_truncate_logs!()
      message = Ecto.Changeset.get_field(changeset, :message)

      all = Repo.all(from l in Log, where: l.message == ^message, limit: 1)

      case Enum.at(all, 0) do
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
    case Repo.get(FarmbotOS.Log, id) do
      %Log{} = log -> Repo.delete!(log)
      nil -> nil
    end
  end

  @doc "Gets all available logs and deletes them."
  def handle_all_logs do
    Repo.all(from(l in FarmbotOS.Log, order_by: l.inserted_at))
    |> Enum.map(&Repo.delete!/1)
  end

  @doc false
  def dispatch_log(level, verbosity, message, meta)
      when level in @log_types and
             is_number(verbosity) and
             is_binary(message) and
             is_list(meta) do
    %{
      level: level,
      verbosity: verbosity,
      message: message,
      meta: Map.new(meta)
    }
    |> dispatch_log()
  end

  @doc false
  def dispatch_log(params) do
    log = insert_log!(params)
    maybe_espeak(params)
    FarmbotOS.LogExecutor.execute(log)
  end

  defp maybe_espeak(%{message: msg, meta: %{channels: c}}) when is_list(c) do
    espeak? = Enum.member?(c, :espeak) && System.find_executable("espeak")
    if espeak?, do: do_espeak(msg)
  end

  defp maybe_espeak(_), do: nil

  def do_espeak(message) do
    speech =
      message
      |> String.trim()
      |> String.slice(1..400)
      |> inspect()

    :os.cmd('espeak #{speech} --stdout | aplay')
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
