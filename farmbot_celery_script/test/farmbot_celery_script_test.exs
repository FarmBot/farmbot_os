defmodule FarmbotCeleryScriptTest do
  use ExUnit.Case, async: true
  use Mimic

  alias FarmbotCeleryScript.AST
  alias FarmbotCeleryScript.SysCalls.Stubs

  test "uses default values when no parameter is found" do
    sequence_ast =
      %{
        kind: :sequence,
        args: %{
          version: 1,
          locals: %{
            kind: :scope_declaration,
            args: %{},
            body: [
              %{
                kind: :parameter_declaration,
                args: %{
                  label: "foo",
                  default_value: %{
                    kind: :coordinate,
                    args: %{x: 12, y: 11, z: 10}
                  }
                }
              }
            ]
          }
        },
        body: [
          %{
            kind: :move_absolute,
            args: %{
              speed: 921,
              location: %{
                kind: :identifier,
                args: %{label: "foo"}
              },
              offset: %{
                kind: :coordinate,
                args: %{x: 0, y: 0, z: 0}
              }
            }
          }
        ]
      }
      |> AST.decode()

    me = self()

    expect(Stubs, :coordinate, fn x, y, z ->
      %{x: x, y: y, z: z}
    end)

    result = FarmbotCeleryScript.execute(sequence_ast, me)
    assert result = :ok
  end

  test "syscall errors" do
    execute_ast =
      %{
        kind: :rpc_request,
        args: %{label: "hello world"},
        body: [
          %{kind: :read_pin, args: %{pin_number: 1, pin_mode: 0}}
        ]
      }
      |> AST.decode()

    expect(Stubs, :read_pin, fn _, _ -> {:error, "failed to read pin!"} end)
    result = FarmbotCeleryScript.execute(execute_ast, execute_ast)
    assert {:error, "failed to read pin!"} = result

    assert_receive {:step_complete, ^execute_ast, {:error, "failed to read pin!"}}
  end

  test "regular exceptions still occur" do
    execute_ast =
      %{
        kind: :rpc_request,
        args: %{label: "hello world"},
        body: [
          %{kind: :read_pin, args: %{pin_number: 1, pin_mode: 0}}
        ]
      }
      |> AST.decode()

    expect(Stubs, :read_pin, fn _, _ -> raise("big oops") end)

    assert {:error, "big oops"} ==
             FarmbotCeleryScript.execute(execute_ast, execute_ast)

    assert_receive {:step_complete, ^execute_ast, {:error, "big oops"}}
  end
end
