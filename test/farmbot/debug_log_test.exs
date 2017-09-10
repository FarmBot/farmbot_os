defmodule Farmbot.DebugLogTest do
  @moduledoc "#ForTheCoverage"

  use ExUnit.Case

  defmodule SomeFunctionality do
    use Farmbot.DebugLog, color: :PURPLE
  end

  test "makes sure we get functions" do
    assert function_exported?(SomeFunctionality, :debug_log, 1)
  end
end
