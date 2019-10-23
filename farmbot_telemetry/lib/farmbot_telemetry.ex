defmodule FarmbotTelemetry do
  @moduledoc """
  Interface for farmbot system introspection and metrics
  """

  @typedoc "Type of telemetry data"
  @type kind() :: :event | :metric

  @typedoc "Classifier for telemetry data"
  @type subsystem() :: atom()

  @typedoc "Name of subsystem measurement data"
  @type measurement() :: atom()

  @typedoc "Value of subsystem measurement data"
  @type value() :: number()

  @typedoc "Metadata for a telemetry event"
  @type meta() :: map()

  @doc "Merges environment data with existing metadata"
  @spec telemetry_meta(Macro.Env.t(), map()) :: meta()
  def telemetry_meta(env, meta) do
    Map.merge(meta, %{
      module: env.module,
      file: env.file,
      line: env.line,
      function: env.function
    })
  end

  @doc "Execute a telemetry event"
  defmacro event(subsystem, measurement, value, meta \\ %{}) do
    quote location: :keep do
      FarmbotTelemetry.bare_telemetry(
        :event,
        unquote(subsystem),
        unquote(measurement),
        unquote(value),
        DateTime.utc_now(),
        FarmbotTelemetry.telemetry_meta(__ENV__, unquote(Macro.escape(meta)))
      )
    end
  end

  @doc "Execute a telemetry metric"
  defmacro metric(subsystem, measurement, value, meta \\ %{}) do
    quote location: :keep do
      FarmbotTelemetry.bare_telemetry(
        :metric,
        unquote(subsystem),
        unquote(measurement),
        unquote(value),
        DateTime.utc_now(),
        FarmbotTelemetry.telemetry_meta(__ENV__, unquote(Macro.escape(meta)))
      )
    end
  end

  @doc "Function responsible for firing telemetry events"
  @spec bare_telemetry(kind(), subsystem(), measurement(), value(), DateTime.t(), meta()) :: :ok
  def bare_telemetry(kind, subsystem, measurement, value, captured_at, meta) do
    _ =
      :telemetry.execute(
        [:farmbot_telemetry, kind, subsystem],
        %{measurement => value, captured_at: captured_at},
        meta
      )

    _ = :dets.insert(:farmbot_telemetry, {captured_at, kind, subsystem, measurement, value, meta})
  end

  @doc "Attach a logger to a kind and subsystem"
  def attach_logger(kind, subsystem, config \\ []) do
    :telemetry.attach(
      "farmbot-telemetry-logger-#{kind}-#{subsystem}",
      [:farmbot_telemetry, kind, subsystem],
      &FarmbotTelemetry.log_handler/4,
      config
    )
  end

  @doc false
  def log_handler(event, measurements, meta, config) do
    Logger.bare_log(
      config[:level] || :info,
      "#{inspect(event)} | #{inspect(measurements)}",
      Map.to_list(meta)
    )
  end

  @typedoc "Function passed to `consume_telemetry/1`"
  @type consumer_fun() ::
          ({DateTime.t(), kind(), subsystem(), measurement(), value(), meta()} -> :ok | :error)

  @doc "Consume telemetry events"
  def consume_telemetry(fun) do
    all_events = :dets.match_object(:farmbot_telemetry, :_)

    tasks =
      Enum.map(all_events, fn event ->
        {elem(event, 0), Task.async(fn -> fun.(event) end)}
      end)

    _ =
      Enum.map(tasks, fn {created_at, task} ->
        case Task.await(task) do
          :ok -> :dets.delete(:farmbot_telemetry, created_at)
          _ -> :ok
        end
      end)

    :ok
  end
end
