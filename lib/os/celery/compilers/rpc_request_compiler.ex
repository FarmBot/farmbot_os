defmodule FarmbotOS.Celery.Compiler.RPCRequest do
  alias FarmbotOS.Celery.Compiler.Utils

  def rpc_request(%{args: %{label: _label}, body: block}, cs_scope) do
    steps =
      Utils.compile_block(block, cs_scope)
      |> Utils.decompose_block_to_steps()

    [
      quote location: :keep do
        fn ->
          cs_scope = unquote(cs_scope)
          # Quiets the compiler (unused var warning)
          _ = inspect(cs_scope)
          unquote(steps)
        end
      end
    ]
  end
end
