defmodule FarmbotCore.EnigmaHandlerTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.EnigmaHandler
  alias FarmbotCore.Asset.Private.Enigma
  import Farmbot.TestSupport.AssetFixtures

  test "handle up" do
    {:ok, handler} = EnigmaHandler.start_link([], [])
    this = self()

    foo = fn x ->
      send(this, x)
      :ok
    end

    e = enigma()

    :ok = EnigmaHandler.register_up(handler, "farmbot_os.firmware.missing", foo)
    EnigmaHandler.handle_up(handler, e)
    assert_received ^e
  end

  test "handle down" do
    {:ok, handler} = EnigmaHandler.start_link([], [])
    this = self()

    foo = fn x ->
      send(this, x)
      :ok
    end

    e = %Enigma{
      priority: 0,
      local_id: Ecto.UUID.generate(),
      problem_tag: "farmbot_os.firmware.missing"
    }

    :ok = EnigmaHandler.register_down(handler, "farmbot_os.firmware.missing", foo)
    EnigmaHandler.handle_down(handler, e)
    assert_received ^e
  end
end
