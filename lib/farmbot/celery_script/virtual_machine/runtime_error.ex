defmodule Farmbot.CeleryScript.VirtualMachine.RuntimeError do
  @moduledoc "Runtime Error of the Virtual Machine"
  
  alias Farmbot.CeleryScript.VirtualMachine
  defexception [:exception, :machine]

  @doc "Requires a VirtualMachine state, and a message."
  def exception(opts) do
    machine = 
      case Keyword.get(opts, :machine) do
        %VirtualMachine{} = machine -> machine
        _ -> raise ArgumentError, "Machine state was not supplied to #{__MODULE__}."
      end
    exception = Keyword.get(opts, :exception) || raise ArgumentError, 
                                            "Exception was not supplied to #{__MODULE__}."
    %__MODULE__{machine: machine, exception: exception}
  end

  @doc false
  def message(%__MODULE__{exception: ex}) do
    Exception.message(ex)
  end

  @type t :: %__MODULE__{
    exception: Exception.t,
    machine: Farmbot.CeleryScript.VirtualMachine.t
  }
end
