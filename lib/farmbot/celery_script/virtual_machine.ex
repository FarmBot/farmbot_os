defmodule Farmbot.CeleryScript.VirtualMachine do
  @moduledoc "Virtual Machine."
 
  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.VirtualMachine.{
    InstructionSet,
    StackFrame
  }
  alias Farmbot.CeleryScript.VirtualMachine.RuntimeError, as: VmError

  use Farmbot.DebugLog

  @typep instruction_set :: InstructionSet.t
  @typep ast :: Ast.t
  @typep stack_frame :: StackFrame.t

  defstruct [
    instruction_set: %InstructionSet{}, 
    call_stack: [], 
    program: [],
    pc: -1,
    running: true
  ]

  @typedoc "State of a virtual machine."
  @type t :: %__MODULE__{
    instruction_set: instruction_set,
    call_stack: [stack_frame],
    program: [ast],
    pc: integer,
    running: boolean,
  }

  # increment the program counter by one.
  defp inc_pc(%__MODULE__{pc: pc} = vm), do: %{vm | pc: pc + 1} 
  
  def step(%__MODULE__{running: true} = vm) do
    vm
    |> inc_pc()
    |> do_step()
  end

  def step(%__MODULE__{running: false} = vm), do: vm
  
  defp do_step(%__MODULE__{} = vm) do
    case vm.program |> Enum.at(vm.pc) do
      %Ast{kind: kind, args: args, body: body} = ast -> 
        debug_log "doing: #{inspect ast}"

        # Turn kind into an instruction
        instruction = Module.concat([kind])
        
        # Lookup the implementation. This could raise.
        impl = vm.instruction_set[instruction]

        # Build a new stack frame and put it on the stack.
        sf = %StackFrame{return_address: vm.pc, args: args, body: body}
        vm = %{vm | call_stack: [sf | vm.call_stack]}
        try do
          # Execute the implementation.
          impl.eval(vm)
        rescue
          ex in VmError -> reraise(ex, System.stacktrace())
          ex -> raise VmError, machine: vm, exception: ex  
        end
      nil -> %{vm | running: false}
    end
  end
end
