defmodule FarmbotTelemetry do
  @moduledoc """
  Interface for farmbot system introspection and metrics
  """

  @typedoc "Classification of telemetry event"
  @type class() :: event_class() | metric_class()

  @typedoc "Event classes are events that have no measurable value"
  @type event_class() :: atom()

  @typedoc "Metric classes are events that have a measurable value"
  @type metric_class() :: atom()

  @typedoc "Type within an event"
  @type event_type() :: atom()

  @typedoc "Action withing a type"
  @type event_action() :: atom()

  @typedoc "Value of a metric event"
  @type metric_value() :: term()

  @typedoc """
  1st arg passed to a `handler` if the type was an event
      [:farmbot_telemetry, :event, t/event_class()]
  """
  @type event_class_path() :: [atom()]

  @typedoc "2nd arg passed to a `handler` if the type was an event"
  @type event_class_data() :: %{
          required(:type) => event_type(),
          required(:action) => event_action(),
          required(:timestamp) => DateTime.t()
        }

  @typedoc """
  1st arg passed to a `handler` if the type was a metric
      [:farmbot_telemetry, :metric, t/metric_class()]
  """
  @type metric_class_path() :: [atom()]

  @typedoc "2nd arg passed to a `handler` if the type was a metric"
  @type metric_class_data() :: %{
          required(:value) => metric_value(),
          required(:timestamp) => DateTime.t()
        }

  @typedoc "3rd arg passed to a `handler`"
  @type meta() :: %{
          required(:module) => module() | nil,
          required(:file) => Path.t() | nil,
          required(:line) => pos_integer() | nil,
          required(:function) => {atom, 0 | pos_integer()} | nil
        }

  @typedoc "4th arg passed to a `handler`"
  @type config() :: term()

  @typedoc "Function that handles telemetry data"
  @type handler() ::
          (event_class_path(), event_class_data(), meta(), config() -> any())
          | (metric_class_path(), metric_class_data(), meta(), config() -> any())

  @doc "Execute a telemetry event"
  defmacro event(class, type, action, meta \\ %{}) do
    meta =
      Map.merge(meta, %{
        module: __ENV__.module,
        file: __ENV__.file,
        line: __ENV__.line,
        function: __ENV__.function
      })

    quote location: :keep do
      :telemetry.execute(
        [:farmbot_telemetry, :event, unquote(class)],
        %{type: unquote(type), action: unquote(action), timestamp: DateTime.utc_now()},
        unquote(Macro.escape(meta))
      )
    end
  end

  @doc "Execute a telemetry metric"
  defmacro metric(class, value, meta \\ %{}) do
    meta =
      Map.merge(meta, %{
        module: __ENV__.module,
        file: __ENV__.file,
        line: __ENV__.line,
        function: __ENV__.function
      })

    quote location: :keep do
      :telemetry.execute(
        [:farmbot_telemetry, :metric, unquote(class)],
        %{value: unquote(value), timestamp: DateTime.utc_now()},
        unquote(Macro.escape(meta))
      )
    end
  end

  @doc "Attach a handler to an event"
  @spec attach(String.t(), event_class_path() | metric_class_path(), handler(), config()) :: any()
  def attach(handler_id, event, handler, config \\ []) do
    :telemetry.attach(handler_id, event, handler, config)
  end

  @doc "Helper to attach the log handler to an event"
  @spec attach_logger(event_class_path() | metric_class_path(), config()) :: any()
  def attach_logger(event, config \\ [level: :info]) do
    attach(
      "logger.#{:erlang.phash2({node(), :erlang.now()})}",
      event,
      &FarmbotTelemetry.log_handler/4,
      config
    )
  end

  @doc "Helper to send a message to the current processes when a matching event is dispatched"
  @spec attach_recv(event_class_path() | metric_class_path(), config()) :: any()
  def attach_recv(event, config \\ [pid: self()]) do
    attach(
      "recv.#{:erlang.phash2({node(), :erlang.now()})}",
      event,
      &Kernel.send(&4[:pid], {&1, &2, &3, &4}),
      config
    )
  end

  @doc false
  def log_handler(event, data, meta, config) do
    msg =
      case event do
        [:farmbot_telemetry, :event, class] ->
          %{type: type, action: action} = data
          "#{class}.#{type}.#{action}"

        [:farmbot_telemetry, :metric, class] ->
          %{value: value} = data
          "#{class}.#{value}=#{value}"
      end

    Logger.bare_log(config[:level] || :debug, msg, Map.to_list(meta))
  end

  @doc "Helper to generate a path for event names"
  @spec event_class(event_class()) :: event_class_path()
  def event_class(class), do: [:farmbot_telemetry, :event, class]

  @doc "Helper to generate a path for metric names"
  @spec metric_class(metric_class()) :: metric_class_path()
  def metric_class(class), do: [:farmbot_telemetry, :metric, class]
end
