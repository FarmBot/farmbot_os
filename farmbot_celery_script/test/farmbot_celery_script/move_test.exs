defmodule FarmbotCeleryScript.MoveTest do
  use ExUnit.Case, async: false
  use Mimic
  alias FarmbotCeleryScript.{AST, Compiler}

  alias FarmbotCeleryScript.SysCalls, warn: false

  setup :verify_on_exit!

  test "move" do
    ast =
      "test/fixtures/move.json"
      |> File.read!()
      |> Jason.decode!()
      |> AST.decode()

    _ = compile(ast)
  end

  defp compile(ast) do
    IO.puts("TODO: Put this into helpers module.")

    ast
    |> Compiler.compile_ast([])
    |> Macro.to_string()
    |> Code.format_string!()
    |> IO.iodata_to_binary()
  end

  # defp strip_nl(text) do
  #   IO.puts("TODO: Put this into helpers module.")
  #   String.trim_trailing(text, "\n")
  # end
end
