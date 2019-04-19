defmodule FarmbotCore.AlertHandlerTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.AlertHandler
  alias FarmbotCore.Asset.Private.Alert
  import Farmbot.TestSupport.AssetFixtures

  test "handle up" do
    {:ok, handler} = AlertHandler.start_link([], [])
    this = self()

    foo = fn x ->
      send(this, x)
      :ok
    end

    e = alert()

    :ok = AlertHandler.register_up(handler, "farmbot_os.firmware.missing", foo)
    AlertHandler.handle_up(handler, e)
    assert_received ^e
  end

  test "handle down" do
    {:ok, handler} = AlertHandler.start_link([], [])
    this = self()

    foo = fn x ->
      send(this, x)
      :ok
    end

    e = %Alert{
      priority: 0,
      local_id: Ecto.UUID.generate(),
      problem_tag: "farmbot_os.firmware.missing"
    }

    :ok = AlertHandler.register_down(handler, "farmbot_os.firmware.missing", foo)
    AlertHandler.handle_down(handler, e)
    assert_received ^e
  end
end
