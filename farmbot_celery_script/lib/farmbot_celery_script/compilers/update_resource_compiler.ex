defmodule FarmbotCeleryScript.Compiler.UpdateResource do
  # alias FarmbotCeleryScript.Compiler

  def coordinate(_ast, _env) do
    raise "TODO: coordinate"
  end

  def named_pin(_ast, _env) do
    raise "TODO: named_pin"
  end

  def point(_ast, _env) do
    raise "TODO: point"
  end

  def tool(_ast, _env) do
    raise "TODO: tool"
  end

  def update_resource(_ast, _env) do
    raise "Its here!"

    quote do
      # FarmbotCeleryScript.SysCalls.update_resource(
      #   unquote(Compiler.compile_ast(kind, env)),
      #   unquote(Compiler.compile_ast(id, env)),
      #   unquote(Macro.escape(params))
      # )
    end
  end
end
