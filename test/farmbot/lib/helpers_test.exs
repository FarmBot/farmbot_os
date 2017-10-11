defmodule Farmbot.Lib.HelpersTest do
  @moduledoc "Tests helper functions."

  use ExUnit.Case

  test "tests uuid function" do
    refute Farmbot.Lib.Helpers.uuid?("123,123,123")
    assert Farmbot.Lib.Helpers.uuid?(UUID.uuid1())
  end
end

defmodule F do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], [])
  end

  def init([]) do
    children = [
      worker(SystemRegistry.Monitor, [
        [:state, :network_interface, "wlan0", :ipv4_address],
        {__MODULE__, :netchange, [:old, :new]}
      ])
    ]

    supervise(children, strategy: :one_for_one)
  end

  def netchange(_old, _new) do
    # Do something when the key changes
  end
end
