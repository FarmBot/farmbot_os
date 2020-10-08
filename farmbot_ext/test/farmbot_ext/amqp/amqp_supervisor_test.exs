defmodule FarmbotExt.AMQP.SupervisorTest do
  use ExUnit.Case, async: false
  use Mimic

  alias FarmbotExt.AMQP.Supervisor

  setup :verify_on_exit!

  test "children" do
    results = Supervisor.children()

    expected = [
      {FarmbotExt.AMQP.ConnectionWorker, [token: nil, email: "test@test.com"]},
      {FarmbotExt.AMQP.ChannelSupervisor, [nil]}
    ]

    assert results == expected
  end
end
