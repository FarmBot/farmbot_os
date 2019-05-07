defmodule FarmbotExt.AMQP.AutoSyncChannelTest do
  use ExUnit.Case
  alias FarmbotExt.AMQP.AutoSyncChannel
  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  setup do
    # FarmbotExt.API.PreloaderApi is a behaviour
    jwt = %FarmbotExt.JWT{}
    {:ok, pid} = AutoSyncChannel.start_link([jwt: jwt], [])
    %{chan: pid}
  end

  test "spawns an AutoSyncChannel", %{chan: chan} do
    IO.inspect(:sys.get_state(chan))
    expect(Lol, :preload_all, fn -> :ok end)
    IO.inspect(Lol.preload_all())
  end

  test "blah" do
    expect(Lol, :preload_all, fn -> :ok end)
    IO.inspect(Lol.preload_all())
  end

  test "blah x 2" do
    expect(Lol, :preload_all, fn -> :nope end)
    IO.inspect(Lol.preload_all())
  end
end
