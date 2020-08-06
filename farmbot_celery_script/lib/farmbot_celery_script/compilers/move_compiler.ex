defmodule FarmbotCeleryScript.Compiler.Move do
  # alias FarmbotCeleryScript.Compiler

  def move(%{} = ast, env) do
    IO.inspect(%{
      ast: ast,
      env: env
    },
    label: "==== Inside `move` compiler")
  end
end
