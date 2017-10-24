defmodule Farmbot.CeleryScript.VirtualMachine do
  @moduledoc "Executes CeleryScript"

  alias Farmbot.CeleryScript.AST
  alias AST.Compiler
  alias Farmbot.CeleryScript.VirtualMachine.{InstructionSet, RuntimeError}

  defmodule State do
    @moduledoc false

    defstruct instruction_set: struct(InstructionSet)
  end

  def execute(ast, state \\ %State{})

  def execute(%AST{} = ast, state) do
    ast |> Compiler.compile(state.instruction_set)
  end
end
