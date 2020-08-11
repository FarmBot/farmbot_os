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
    stub_current_location()

    expect(Stubs, :move_absolute, 1, fn _, _, _, _, _, _ ->
      :ok
    end)

    eval_celeryscript("test/fixtures/move_identifier.json", %{
      "parent" => %{kind: :coordinate, args: %{x: 999, y: 888, z: 777}}
    })
  end

  test "evaluates Lua code" do
    stub_current_location()

    body_item = %{
      kind: "axis_overwrite",
      args: %{
        axis: "y",
        axis_operand: %{
          kind: "lua",
          args: %{
            lua: "({x = 23}).x"
          }
        }
      }
    }

    eval_body_item(body_item, %{})
  end

  defp eval_body_item(body_item, variables) do
    stringy_code =
      %{kind: "move", args: %{}, body: [body_item]}
      |> AST.decode()
      |> compile()

    Code.eval_string("better_params = #{inspect(variables)}\n" <> stringy_code)
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

  defp stub_current_location() do
    expect(Stubs, :get_current_x, fn -> 100.00 end)
    expect(Stubs, :get_current_y, fn -> 200.00 end)
    expect(Stubs, :get_current_z, fn -> 300.00 end)
  end
end
