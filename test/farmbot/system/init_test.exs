defmodule Farmbot.System.InitTest do
  @moduledoc "Tests init behaviour"
  use ExUnit.Case

  test "returns a supervisor spec" do
    ret = Farmbot.System.Init.fb_init(SomeMod, [])
    assert ret == {SomeMod, {SomeMod, :start_link, []}, :permanent, :infinity, :supervisor, [SomeMod]}
  end
end
