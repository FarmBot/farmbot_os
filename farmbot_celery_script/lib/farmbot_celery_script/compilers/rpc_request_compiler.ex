defmodule FarmbotCeleryScript.Compiler.RPCRequest do
  import FarmbotCeleryScript.Compiler.Utils

  def rpc_request(%{args: %{label: _label}, body: block}, env) do
    steps = compile_block(block, env) |> decompose_block_to_steps()

    [
      quote location: :keep do
        fn params ->
          # The `better_params` object is a map of CeleryScript
          # variables in the currently executing CeleryScript
          # environment.
          # The current CSVM is a winding maze of macros which
          # makes it difficult for developers to reason about
          # where they are in a sequence execution.
          # Sometimes, that can lead to runtime errors because
          # the CSVM creates a macro that references a non-existent
          # `better_params` map.
          # To prevent runtime exceptions caused by an undefined
          # reference
          # - RC, 13 JAN 21
          better_params = %{no_variables_declared: %{}}
          # Quiets the compiler (unused var warning)
          _ = inspect(better_params)
          _ = inspect(params)
          unquote(steps)
        end
      end
    ]
  end
end
