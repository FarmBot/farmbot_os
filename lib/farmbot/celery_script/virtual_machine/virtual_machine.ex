defmodule Farmbot.CeleryScript.VirtualMachine do
  @moduledoc "Executes CeleryScript"

  alias Farmbot.CeleryScript.AST
  alias AST.Compiler
  alias Farmbot.CeleryScript.VirtualMachine.{InstructionSet, RuntimeError}

  use GenServer
  defmodule State do
    @moduledoc false
    defstruct instruction_set: struct(InstructionSet)
  end

  # alias Farmbot.CeleryScript.VirtualMachine, as: VM
  # Farmbot.HTTP.get!("/api/sequences/2").body |> Poison.decode! |> Farmbot.CeleryScript.AST.parse
  def execute(%AST{} = ast, state \\ struct(State)) do

  end
end
