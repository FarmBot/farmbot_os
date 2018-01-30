defmodule Farmbot.System.RegistryTest do
  use ExUnit.Case
  alias Farmbot.System.Registry

  test "subscribes and dispatches global events" do
    Registry.subscribe(self())
    Registry.dispatch(:hello, :world)
    assert_receive {Registry, {:hello, :world}}
  end
end
