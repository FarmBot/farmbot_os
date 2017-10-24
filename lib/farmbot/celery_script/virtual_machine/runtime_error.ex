defmodule Farmbot.CeleryScript.VirtualMachine.RuntimeError do
  defexception [:message, :cs_stack_trace]

  def exception(opts) do
    message = Keyword.fetch!(opts, :message)
    cs_stack_trace = Keyword.fetch!(opts, :cs_stack_trace)
    %__MODULE__{message: message, cs_stack_trace: cs_stack_trace}
  end

end
