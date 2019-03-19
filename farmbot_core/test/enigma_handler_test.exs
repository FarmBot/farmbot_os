defmodule FarmbotCore.EnigmaHandlerTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.EnigmaHandler
  alias FarmbotCore.Asset.Private.Enigma

  test "handle up" do
    {:ok, handler} = EnigmaHandler.start_link([], [])
    this = self()

    foo = fn x ->
      send(this, x)
      :ok
    end

    e = %Enigma{
      priority: 0,
      local_id: Ecto.UUID.generate(),
      problem_tag: "firmware.missing"
    }

    :ok = EnigmaHandler.register_up(handler, "firmware.missing", foo)
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
      problem_tag: "firmware.missing"
    }

    :ok = EnigmaHandler.register_down(handler, "firmware.missing", foo)
    EnigmaHandler.handle_down(handler, e)
    assert_received ^e
  end
end
