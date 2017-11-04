defmodule Compiler do
  alias Farmbot.CeleryScript.AST
  def compile(file) do
    File.read!(file)
    |> do_compile
  end

  defp do_compile(bin, acc) do

  end
end
Compiler.compile("sequence.celery")
