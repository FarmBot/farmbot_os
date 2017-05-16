defmodule Farmbot.DatabaseTest do
  alias Farmbot.TestHelpers
  use ExUnit.Case, async: false

  setup_all do
    [token: TestHelpers.login()]
  end

  test "Syncing of resources on load" do
    Farmbot.Sync.sync()
  end
end
