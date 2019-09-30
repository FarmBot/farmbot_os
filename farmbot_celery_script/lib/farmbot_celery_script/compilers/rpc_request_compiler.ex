defmodule FarmbotCeleryScript.Compiler.RPCRequest do
  import FarmbotCeleryScript.Compiler.Utils

  def rpc_request(%{args: %{label: _label}, body: block}, env) do
    steps = compile_block(block, env) |> decompose_block_to_steps()

    quote location: :keep do
      fn params ->
        # This quiets a compiler warning if there are no variables in this block
        _ = inspect(params)
        unquote(steps)
      end
    end
  end
end
