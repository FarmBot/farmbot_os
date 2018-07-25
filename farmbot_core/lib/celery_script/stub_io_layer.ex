defmodule Farmbot.CeleryScript.StubIOLayer do
  @behaviour Farmbot.CeleryScript.IOLayer

  def handle_io(ast) do
    IO.puts "#{ast.kind} not implemented."
    # {:error, "#{ast.kind} not implemented."}
    :ok
  end
end
