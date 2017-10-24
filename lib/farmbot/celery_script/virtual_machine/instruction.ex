defmodule Farmbot.CeleryScript.VirtualMachine.Instruction do
  @moduledoc "Behaviour for implementing CeleryScript nodes."
  alias Farmbot.CeleryScript.AST

  @callback precompile(AST.t) :: {:ok, AST.t} | {:error, term}

  @callback execute() :: {:ok, Ast.t} | {:error, term}
end
