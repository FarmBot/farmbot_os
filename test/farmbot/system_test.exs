defmodule Farmbot.SystemTest do
  @moduledoc "Tests system functionaity."
  use ExUnit.Case

  test "does factory reset" do
    Farmbot.System.factory_reset("hey something bad happened!")
    last = Farmbot.Test.SystemTasks.fetch_last()
    assert last == {:factory_reset, "hey something bad happened!"}
  end

  test "does reboot" do
    Farmbot.System.reboot("goodbye cruel world!")
    last = Farmbot.Test.SystemTasks.fetch_last()
    assert last == {:reboot, "goodbye cruel world!"}
  end

  test "does shutdown" do
    Farmbot.System.shutdown "see you soon!"
    last = Farmbot.Test.SystemTasks.fetch_last()
    assert last == {:shutdown, "see you soon!"}
  end
end
