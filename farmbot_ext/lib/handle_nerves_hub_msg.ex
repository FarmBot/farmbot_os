defmodule Farmbot.Ext.HandleNervesHubMsg do
  @behaviour Farmbot.AMQP.NervesHubTransport
  def configure_certs(_, _), do: :error
  def connect(), do: :error
end
