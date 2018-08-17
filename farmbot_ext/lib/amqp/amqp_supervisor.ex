defmodule Farmbot.AMQP.Supervisor do
  @moduledoc false
  use Supervisor
  import Farmbot.Config, only: [get_config_value: 3]

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    token = get_config_value(:string, "authorization", "token")
    email = get_config_value(:string, "authorization", "email")
    children = [
      {Farmbot.AMQP.ConnectionWorker, [token: token, email: email]},
      {Farmbot.AMQP.ChannelSupervisor, [token]}
    ]
    Supervisor.init(children, [strategy: :one_for_all])
  end
end
