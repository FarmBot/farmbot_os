defmodule FarmbotExt.AMQP.Supervisor do
  @moduledoc """
  Supervises AMQP connections
  """
  use Supervisor
  import FarmbotCore.Config, only: [get_config_value: 3]

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    Supervisor.init(children(), strategy: :one_for_all)
  end

  def children do
    token = get_config_value(:string, "authorization", "token")
    email = get_config_value(:string, "authorization", "email")
    config = Application.get_env(:farmbot_ext, __MODULE__) || []

    Keyword.get(config, :children, [
      {FarmbotExt.AMQP.ConnectionWorker, [token: token, email: email]},
      {FarmbotExt.AMQP.ChannelSupervisor, [token]},
      FarmbotExt.MQTT.Handler.mqtt_child(token)
    ])
  end
end
