defmodule FarmbotTelemetry do
  @moduledoc """
  Interface for farmbot system introspection and metrics
  """

  @typedoc "Type of telemetry data"
  @type kind() :: :event | :metric

  @typedoc "UUID of the telemetry data"
  @type uuid() :: String.t()

  @typedoc "Classifier for telemetry data"
  @type subsystem() :: atom()

  @typedoc "Name of subsystem measurement data"
  @type measurement() :: atom()

  @typedoc "Value of subsystem measurement data"
  @type value() :: number()

  @typedoc "Metadata for a telemetry event"
  @type meta() :: Keyword.t()

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
  def event(subsystem, measurement_or_event_name, value \\ nil, meta \\ [])

  def event(subsystem, measurement, value, meta)
      when is_atom(subsystem) and
             is_atom(measurement) and
             is_list(meta) do
    FarmbotTelemetry.bare_telemetry(
      UUID.uuid4(),
      :event,
      subsystem,
      measurement,
      value,
      DateTime.utc_now(),
      Keyword.merge(meta,
        module: __ENV__.module,
        file: __ENV__.file,
        line: __ENV__.line,
        function: __ENV__.function
      )
    )
  end

  def event(subsystem, measurement, value, meta) do
    Mix.raise("""
    Unknown args for telemetry event:
    #{inspect(subsystem)}, #{inspect(measurement)}, #{inspect(value)}, #{inspect(meta)}
    """)
  end

  @doc """
  Function responsible for firing telemetry events
  stores telemetry event in `dets` table to be cached until
  farmbot has a chance to dispatch them.  This is required because
  dispatching can only be done when farmbot as an active internet
  connection.

  Dispatching is done by calling the `consume_telemetry/1` function.
  """
  @spec bare_telemetry(
          uuid,
          kind(),
          subsystem(),
          measurement(),
          value(),
          DateTime.t(),
          meta()
        ) ::
          :ok
  def bare_telemetry(
        uuid,
        kind,
        subsystem,
        measurement,
        value,
        captured_at,
        meta
      )
      when is_binary(uuid) and is_atom(kind) and is_atom(subsystem) and
             is_atom(measurement) and
             is_list(meta) do
    _ =
      :telemetry.execute(
        [:farmbot, kind, subsystem],
        %{
          measurement: measurement,
          value: value,
          captured_at: captured_at,
          uuid: uuid
        },
        Map.new(meta)
      )

    _ =
      :dets.insert(
        :farmbot,
        {uuid, captured_at, kind, subsystem, measurement, value, Map.new(meta)}
      )
  end

  @doc "Attach a logger to a kind and subsystem"
  def attach_logger(kind, subsystem, config \\ []) do
    :telemetry.attach(
      "farmbot-telemetry-logger-#{kind}-#{subsystem}-#{UUID.uuid4()}",
      [:farmbot, kind, subsystem],
      &FarmbotTelemetry.log_handler/4,
      config
    )
  end

  @doc "Attach a message sender to a kind and subsystem"
  def attach_recv(kind, subsystem, pid) do
    :telemetry.attach(
      "farmbot-telemetry-recv-#{kind}-#{subsystem}-#{UUID.uuid4()}",
      [:farmbot, kind, subsystem],
      &Kernel.send(pid, {&1, &2, &3, &4}),
      pid: self()
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
          ({uuid(), DateTime.t(), kind(), subsystem(), measurement(), value(),
            meta()} ->
             :ok | any())

  @doc """
  Syncronously consume telemetry events.

  Function will be evaluated once for every telemetry event,
  blocking until complete. Function should complete within
  5 seconds per each event. Function should return `:ok` if
  the event was successfully consumed, anything else will
  cause the event to be put back on the queue
  """
  @spec consume_telemetry(consumer_fun()) :: :ok
  def consume_telemetry(fun) do
    all_events = :dets.match_object(:farmbot, :_)

    tasks =
      Enum.map(all_events, fn event ->
        {elem(event, 0), Task.async(fn -> fun.(event) end)}
      end)

    _ =
      Enum.map(tasks, fn {uuid, task} ->
        result =
          try do
            Task.await(task)
          catch
            kind, err ->
              msg = "Telemetry error: #{kind} #{inspect(err)}"
              IO.warn(msg, __STACKTRACE__)
              nil
          end

        case result do
          :ok -> :dets.delete(:farmbot, uuid)
          _ -> :ok
        end
      end)

    :ok
  end
end
