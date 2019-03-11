defmodule FarmbotExt.HandleNervesHubMsg do
  @behaviour FarmbotExt.AMQP.NervesHubTransport
  def configure_certs(_, _), do: :error
  def connect(), do: :error
end
