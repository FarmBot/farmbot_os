defmodule Farmbot.CeleryScript.VirtualMachine.StackFrame do
  @moduledoc "Frame of the callstack"
  
  alias Farmbot.CeleryScript.Ast
  @enforce_keys [:args, :return_address, :body]
  defstruct [:args, :return_address, :body]

  @typedoc "Part of a call stack."
  @type t :: %__MODULE__{
    args: Ast.args,
    body: Ast.body,
    return_address: integer
  }
end
