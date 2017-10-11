defmodule Farmbot.CeleryScript.VirtualMachine.StackFrameTest do
  @moduledoc "Tests the stackframe struct"
  use ExUnit.Case

  alias Farmbot.CeleryScript.VirtualMachine.StackFrame

  test "creates a stack frame" do
    %StackFrame{body: [], args: %{}, return_address: 1234}
  end
end
