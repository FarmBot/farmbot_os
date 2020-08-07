defmodule FarmbotCeleryScript.MoveTest do
  use ExUnit.Case, async: false
  use Mimic

  alias FarmbotCeleryScript.{
    AST,
    Compiler,
    SysCalls.Stubs
  }

  alias FarmbotCeleryScript.SysCalls, warn: false

  setup :verify_on_exit!

  test "move" do
    ast =
      "test/fixtures/move.json"
      |> File.read!()
      |> Jason.decode!()
      |> AST.decode()

    expect(Stubs, :get_current_x, 1, fn -> 100.00 end)
    expect(Stubs, :get_current_y, 1, fn -> 200.00 end)
    expect(Stubs, :get_current_z, 1, fn -> 300.00 end)

    IO.puts(compile(ast))
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
