defmodule FarmbotOS.Celery.Compiler.DataControl do
  alias FarmbotOS.Celery.Compiler

  # compiles coordinate
  # Coordinate should return a vec3
  def coordinate(%{args: %{x: x, y: y, z: z}}, cs_scope) do
    quote location: :keep do
      FarmbotOS.Celery.SysCallGlue.coordinate(
        unquote(Compiler.celery_to_elixir(x, cs_scope)),
        unquote(Compiler.celery_to_elixir(y, cs_scope)),
        unquote(Compiler.celery_to_elixir(z, cs_scope))
      )
    end
  end

  # compiles point
  def point(%{args: %{pointer_type: type, pointer_id: id}}, cs_scope) do
    quote location: :keep do
      FarmbotOS.Celery.SysCallGlue.point(
        unquote(Compiler.celery_to_elixir(type, cs_scope)),
        unquote(Compiler.celery_to_elixir(id, cs_scope))
      )
    end
  end

  # compile a named pin
  def named_pin(%{args: %{pin_id: id, pin_type: type}}, cs_scope) do
    quote location: :keep do
      FarmbotOS.Celery.SysCallGlue.named_pin(
        unquote(Compiler.celery_to_elixir(type, cs_scope)),
        unquote(Compiler.celery_to_elixir(id, cs_scope))
      )
    end
  end

  def tool(%{args: %{tool_id: tool_id}}, cs_scope) do
    quote location: :keep do
      FarmbotOS.Celery.SysCallGlue.get_toolslot_for_tool(
        unquote(Compiler.celery_to_elixir(tool_id, cs_scope))
      )
    end
  end
end
