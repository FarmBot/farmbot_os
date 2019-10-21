defmodule FarmbotTelemetry do
  @moduledoc """
  Interface for farmbot system introspection
  """
  alias FarmbotTelemetry.EventClass

  @typedoc "Module that implements the FarmbotTelemetry.EventClass behaviour"
  @type class() :: module()

  @typedoc "First argument to the handler"
  @type event() :: nonempty_maybe_improper_list(class(), EventClass.type())

  @typedoc "Second argument to the handler"
  @type data() :: %{
          required(:action) => EventClass.action(),
          required(:timestamp) => DateTime.t()
        }

  @type meta() :: map()

  @typedoc "Term that will be passed to the handler."
  @type config() :: any()

  @typedoc "Module that implements the "
  @type handler() :: (event(), data(), meta(), config() -> any())

  @typedoc "required options for FarmbotTelemetry"
  @type opt() ::
          {:class, class()}
          | {:handler, handler()}
          | {:config, config()}

  @typedoc false
  @type opts :: [opts]

  @doc false
  @spec child_spec(opts) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: opts[:class],
      start: {__MODULE__, :attach, [opts]}
    }
  end

  @doc false
  @spec attach(opts) :: GenServer.on_start()
  def attach(opts) do
    class = opts[:class]
    handler_id = opts[:handler_id]
    handler = opts[:handler]
    config = opts[:config]

    for {type, _actions} <- class.matrix() do
      _ = :telemetry.attach(handler_id, [class, type], handler, config)
    end

    :ignore
  end

  @doc false
  defmacro __using__(_opts) do
    quote do
      alias FarmbotTelemetry.{
              AMQPEventClass,
              DNSEventClass,
              HTTPEventClass,
              NetworkEventClass
            },
            warn: false

      require FarmbotTelemetry
    end
  end

  @doc "Execute a telemetry event. `type` and `action` will be validated"
  def execute(class, type, action, meta \\ %{}) do
    :telemetry.execute([class, type], %{action: action, timestamp: DateTime.utc_now()}, meta)
    # quote location: :keep,
    #       bind_quoted: [class: class, type: type, action: action, meta: Macro.escape(meta)] do
    #   # unless {type, action} in class.matrix() do
    #   #   raise """
    #   #   #{type}.#{action} is unknown for #{class}
    #   #   """
    #   # end

    #   _ = FarmbotTelemetry.unsafe_execute(class, type, action, meta)
    # end
  end

  @doc false
  def unsafe_execute(class, type, action, meta \\ %{}) do
    :telemetry.execute([class, type], %{action: action, timestamp: DateTime.utc_now()}, meta)
  end
end
