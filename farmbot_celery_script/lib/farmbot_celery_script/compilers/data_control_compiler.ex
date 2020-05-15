defmodule FarmbotCeleryScript.Compiler.DataControl do
  alias FarmbotCeleryScript.Compiler

  def resource(ast, _env) do
    IO.puts("======")
    IO.inspect(ast)
    # %FarmbotCeleryScript.AST{
    #   args: %{resource_id: 0, resource_type: "Device"},
    #   body: [],
    #   comment: nil,
    #   kind: :resource,
    #   meta: nil
    # }
    raise "TODO: Pull resource from DB?"
  end

  # compiles coordinate
  # Coordinate should return a vec3
  def coordinate(%{args: %{x: x, y: y, z: z}}, env) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.coordinate(
        unquote(Compiler.compile_ast(x, env)),
        unquote(Compiler.compile_ast(y, env)),
        unquote(Compiler.compile_ast(z, env))
      )
    end
  end

  # compiles point
  def point(%{args: %{pointer_type: type, pointer_id: id}}, env) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.point(
        unquote(Compiler.compile_ast(type, env)),
        unquote(Compiler.compile_ast(id, env))
      )
    end
  end

  # compile a named pin
  def named_pin(%{args: %{pin_id: id, pin_type: type}}, env) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.named_pin(
        unquote(Compiler.compile_ast(type, env)),
        unquote(Compiler.compile_ast(id, env))
      )
    end
  end

  def tool(%{args: %{tool_id: tool_id}}, env) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.get_toolslot_for_tool(
        unquote(Compiler.compile_ast(tool_id, env))
      )
    end
  end
end
