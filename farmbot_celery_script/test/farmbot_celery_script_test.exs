defmodule FarmbotCeleryScriptTest do
  use ExUnit.Case, async: true
  alias FarmbotCeleryScript.AST
  alias Farmbot.TestSupport.CeleryScript.TestSysCalls

  setup do
    {:ok, _shim} = TestSysCalls.checkout()
    :ok
  end

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
                    args: %{x: 129, y: 129, z: 129}
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

    :ok =
      TestSysCalls.handle(TestSysCalls, fn
        :move_absolute, args ->
          send(me, {:move_absolute, args})
          :ok

        :coordinate, [x, y, z] ->
          %{x: x, y: y, z: z}
      end)

    _ = FarmbotCeleryScript.execute(sequence_ast, me)
    assert_receive {:step_complete, ^me, :ok}
    assert_receive {:move_absolute, [129, 129, 129, 921]}
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

    :ok =
      TestSysCalls.handle(TestSysCalls, fn
        :read_pin, _ -> {:error, "failed to read pin!"}
      end)

    assert {:error, "failed to read pin!"} = FarmbotCeleryScript.execute(execute_ast, execute_ast)
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

    :ok =
      TestSysCalls.handle(TestSysCalls, fn
        :read_pin, _ -> raise("big oops")
      end)

    assert {:error, "big oops"} == FarmbotCeleryScript.execute(execute_ast, execute_ast)
    assert_receive {:step_complete, ^execute_ast, {:error, "big oops"}}
  end
end
