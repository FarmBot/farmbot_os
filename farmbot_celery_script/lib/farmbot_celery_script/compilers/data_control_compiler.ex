defmodule FarmbotCeleryScript.Compiler.DataControl do
  alias FarmbotCeleryScript.Compiler

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

  def resource_update(
        %{args: %{resource_type: kind, resource_id: id, label: label, value: value}, body: body},
        env
      ) do
    initial = %{label => value}
    # Technically now body isn't supported by this node.
    extra =
      Map.new(body, fn %{args: %{label: label, data_value: value}} ->
        {label, value}
      end)

    # Make sure the initial stuff higher most priority
    params = Map.merge(extra, initial)

    quote do
      FarmbotCeleryScript.SysCalls.resource_update(
        unquote(Compiler.compile_ast(kind, env)),
        unquote(Compiler.compile_ast(id, env)),
        unquote(Macro.escape(params))
      )
    end
  end
end
