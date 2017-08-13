defmodule Farmbot.CeleryScript.VirtualMachine.InstructionSet do
  @moduledoc """
  Instruction Set for a virtual machine.
  This will allow swapping of instructions between machine executions.
  """
  
  alias Farmbot.CeleryScript.VirtualMachine.UndefinedInstructionError 
  
  defstruct [
    instructions: %{
      # TODO(Connor) add back all the default modules here.
    } 
  ]

  @typedoc "Instruction Set type."
  @type t :: %__MODULE__{
    instructions: %{optional(module) => module}
  }

  @doc false
  def fetch(%__MODULE__{instructions: instrs}, instr) do
    impl = instrs[instr] || raise UndefinedInstructionError, instr 
    {:ok, impl}
  end
  
  @doc "Builds a new InstructionSet"
  @spec new :: t
  def new do
    # don't use the default implementation.
    %__MODULE__{instructions: %{}}
  end

  @doc "Implement an instruction. "
  @spec impl(t, module, module) :: t
  def impl(%__MODULE__{} = set, instruction, implementation) 
    when is_atom(instruction) and is_atom(implementation)
  do
    implementation
    |> ensure_loaded!
    |> ensure_implemented!

    instrs = Map.put(set.instructions, instruction, implementation)
    %{set | instructions: instrs}
  end
  
  defp ensure_loaded!(impl) do
    case Code.ensure_loaded(impl) do
      {:module, _} -> impl 
      {:error, _} ->
        name = Macro.underscore(impl)
        raise CompileError, description: "Failed to load implementation: #{name}."
    end
  end

  defp ensure_implemented!(impl) do
    unless function_exported?(impl, :eval, 1) do
      name = Macro.underscore(impl)
      raise CompileError, description: "#{name} does not implement CeleryScript."
    end
    impl
  end
end
