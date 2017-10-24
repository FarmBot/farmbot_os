defmodule Farmbot.CeleryScript.AST.Compiler do
  require Logger
  alias Farmbot.CeleryScript.AST
  alias Farmbot.CeleryScript.AST.CompileError
  alias Farmbot.CeleryScript.VirtualMachine.InstructionSet
  import Farmbot.CeleryScript.AST.Compiler.Utils

  def compile(ast, instrs) do
    compiler_debug_log(
      "#{Farmbot.DebugLog.color(:YELLOW)}BEGIN COMPILE: #{inspect(ast)}#{
        Farmbot.DebugLog.color(:NC)
      }"
    )
    compiler_debug_log_begin_step(ast, "ensure_implementation")
    ast = ensure_implementation!(ast, instrs)
    compiler_debug_log_complete_step(ast, "ensure_implementation")
    compiler_debug_log_begin_step(ast, "precompile")
    {state, ast} = precompile!(ast, instrs)
    compiler_debug_log(Map.keys(state) |> Enum.join("\n\n"))
    compiler_debug_log_complete_step(ast, "precompile")
    ast
  end

  def ensure_implementation!(%AST{kind: kind, body: []} = ast, instrs) do
    :ok = do_ensure(kind, instrs)
    ast
  end

  def ensure_implementation!(%AST{kind: kind, body: body} = ast, instrs) do
    :ok = do_ensure(kind, instrs)
    ensure_implementation!(body, instrs)
    ast
  end

  def ensure_implementation!([%AST{kind: kind, body: body} | next], instrs) do
    :ok = do_ensure(kind, instrs)
    ensure_implementation!(body, instrs)
    ensure_implementation!(next, instrs)
  end

  def ensure_implementation!([], _), do: :ok

  defp do_ensure(kind, instrs) do
    compiler_debug_log(kind, "ensure implementation")
    impl = instrs[kind] || raise CompileError, "No implementation for #{kind}"
    if Code.ensure_loaded?(impl) do
      :ok
    else
      raise CompileError, "Implementation module: #{impl} is not loaded."
    end
  end

  # sequence
  # -> execute_sequence
  #    -> move_abs

  def precompile!(ast, instrs, state \\ %{}) do
    impl = instrs[ast.kind]
    if state[ast.__meta__.encoded] do
      compiler_debug_log("#{inspect ast} compiled")
      {state, ast}
    else
      case impl.precompile(ast) do
        {:ok, res} ->
          res = %{res | __meta__: %{res.__meta__ | precompiled: true}}
          state = Map.put(state, res.__meta__.encoded, res)
          {state, ast} = precompile!(res, instrs, state)
          {state, body} = precompile_body(ast.body, instrs, state)
          %{ast | body: body} |> precompile!(instrs, state)
        {:error, reason} -> raise CompileError, reason
      end
    end
  end

  defp precompile_body(body, instrs, state, acc \\ [])

  defp precompile_body([ast | rest], instrs, state, acc) do
    {state, ast} = precompile!(ast, instrs, state)
    acc = [ast | acc]
    precompile_body(rest, instrs, state, acc)
  end

  defp precompile_body([], instrs, state, acc) do
    {state, Enum.reverse(acc)}
  end
end
# Farmbot.HTTP.get!("/api/sequences/2") |> Map.get(:body) |> Poison.decode! |> Farmbot.CeleryScript.AST.parse |> Farmbot.CeleryScript.VirtualMachine.execute
