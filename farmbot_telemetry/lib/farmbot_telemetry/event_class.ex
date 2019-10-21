defprotocol FarmbotTelemetry.EventClass do
  @moduledoc """
  Classificaiton of a telemetry event
  """

  @typedoc "Type of event in relation to the class"
  @type type() :: atom()

  @typedoc "Action in relation to the type"
  @type action() :: atom()

  @doc "mapping of `type` to `action`"
  @callback matrix() :: [{type(), action()}]
end
