defmodule FarmbotExt.AMQP.SupervisorTest do
  use ExUnit.Case, async: false
  use Mimic

  alias FarmbotExt.AMQP.Supervisor

  setup :verify_on_exit!

  test "children" do
    results = Supervisor.children()

    email = System.get_env("FARMBOT_EMAIL")

    expected = [
      {FarmbotExt.AMQP.ConnectionWorker, [token: nil, email: email]},
      {FarmbotExt.AMQP.ChannelSupervisor, [nil]}
    ]

    assert results == expected
  end
end
