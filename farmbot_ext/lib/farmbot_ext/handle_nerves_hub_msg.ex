defmodule FarmbotExt.HandleNervesHubMsg do
  @behaviour FarmbotExt.AMQP.NervesHubChannel
  def configure_certs(_, _), do: :error
  def connect(), do: :error
end
