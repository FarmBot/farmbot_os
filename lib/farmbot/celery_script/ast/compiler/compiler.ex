defmodule Farmbot.CeleryScript.AST.Compiler do
  require Logger
  alias Farmbot.CeleryScript.AST.Compiler.CompileError
  alias Farmbot.CeleryScript.VirtualMachine.InstructionSet

  def compile(ast, %InstructionSet{} = instruction_set) do
    res = ast
    |> tag(:precompile)
    |> ensure_impl(instruction_set)
    |> precompile(instruction_set, [])
    require IEx; IEx.pry
  end

  def tag(ast, step) do
    %{ast | compile_meta: Map.put(ast.compile_meta || %{}, :step, step), body: tag_body(ast.body, step)}
  end

  defp tag_body(body, step, acc \\ [])

  defp tag_body([ast | rest], step, acc) do
    tag_body(rest, step, [tag(ast, step) | acc])
  end

  defp tag_body([], _step, acc), do: Enum.reverse(acc)

  def ensure_impl(ast, %InstructionSet{} = instruction_set) do
    unless instruction_set[ast.kind] do
      raise CompileError, "#{ast.kind} has no implementation."
    end

    unless Code.ensure_loaded?(instruction_set[ast.kind]) do
      raise CompileError, "#{ast.kind} implementation could not be loaded."
    end

    %{ast | body: ensure_impl_body(ast.body, instruction_set)}
  end

  def ensure_impl_body(body, instruction_set, acc \\ [])

  def ensure_impl_body([ast | rest], %InstructionSet{} = instruction_set, acc) do
    ensure_impl_body(rest, instruction_set, [ensure_impl(ast, instruction_set) | acc])
  end

  def ensure_impl_body([], %InstructionSet{} = _instruction_set, acc), do: Enum.reverse(acc)

  def precompile(ast, %InstructionSet{} = instruction_set, cache) do
    md5 = :crypto.hash(:md5, Poison.encode!(ast)) |> Base.encode16
    IO.puts "precompiling: #{inspect ast}: #{inspect ast.compile_meta} => #{md5}"
    IO.inspect cache
    if md5 in cache do
      ast
    else
      cache = [md5 | cache]
      case instruction_set[ast.kind].precompile(ast) do
        {:error, reason} -> raise CompileError, reason
        {:ok, precompiled} ->
          precompiled = %{precompiled | body: precompile_body(precompiled.body, instruction_set, cache)}
          IO.inspect precompiled.compile_meta
          case precompiled.compile_meta do
            nil ->
              precompiled
              |> tag(:precompile)
              |> ensure_impl(instruction_set)
              |> precompile(instruction_set, cache)
              |> tag(:compile)
            %{step: :precompile} -> tag(precompiled, :compile)
          end
      end
    end

  end

  def precompile_body(body, instruction_set, cache, acc \\ [])

  def precompile_body([ast | rest], %InstructionSet{} = instruction_set, cache, acc) do
    precompile_body(rest, instruction_set, cache, [precompile(ast, instruction_set, cache) | acc])
  end

  def precompile_body([], %InstructionSet{} = _instruction_set, _cache, acc), do: Enum.reverse(acc)
end

# Farmbot.HTTP.get!("/api/sequences/2") |> Map.get(:body) |> Poison.decode! |> Farmbot.CeleryScript.AST.parse |> Farmbot.CeleryScript.VirtualMachine.execute
