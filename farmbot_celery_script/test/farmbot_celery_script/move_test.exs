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

  test "move to identifier" do
    expect(Stubs, :get_current_x, 1, fn -> 100.00 end)
    expect(Stubs, :get_current_y, 1, fn -> 200.00 end)
    expect(Stubs, :get_current_z, 1, fn -> 300.00 end)

    expect(Stubs, :move_absolute, 1, fn _, _, _, _, _, _ ->
      :ok
    end)

    eval_celeryscript("test/fixtures/move_identifier.json", %{
      "parent" => %{kind: :coordinate, args: %{x: 999, y: 888, z: 777}}
    })
  end

  defp eval_celeryscript(json_path, variables) do
    stringy_code =
      json_path
      |> File.read!()
      |> Jason.decode!()
      |> AST.decode()
      |> compile()

    Code.eval_string("better_params = #{inspect(variables)}\n" <> stringy_code)
  end

  defp compile(ast) do
    ast
    |> Compiler.compile_ast([])
    |> Macro.to_string()
    |> Code.format_string!()
    |> IO.iodata_to_binary()
  end
end
