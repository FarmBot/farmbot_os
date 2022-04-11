defmodule FarmbotOS.CeleryTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.Celery.AST
  alias FarmbotOS.Celery.SysCallGlue.Stubs

  import ExUnit.CaptureLog

  setup :verify_on_exit!

  @fake_lua_ast [
    {"kind", "rpc_request"},
    {"args", [{"label", "x"}, {"priority", 600}]},
    {"body", [{1, [{"args", []}, {"kind", "nothing"}]}]}
  ]

  test "executing of CS from Lua - OK" do
    %Task{pid: pid} =
      task =
      Task.async(
        FarmbotOS.Celery,
        :execute_from_lua,
        [[@fake_lua_ast], %{}]
      )

    send(pid, {:csvm_done, nil, :ok})
    result = Task.await(task)
    assert result == {[true, nil], %{}}
  end

  test "executing of CS from Lua - error" do
    %Task{pid: pid} =
      task =
      Task.async(FarmbotOS.Celery, :execute_from_lua, [[@fake_lua_ast], %{}])

    send(pid, {:csvm_done, nil, {:error, "x"}})
    result = Task.await(task)
    assert result == {[false, "{:csvm_done, nil, {:error, \"x\"}}"], %{}}
  end

  test "schedule/3" do
    at = DateTime.utc_now()
    ast = AST.decode(%{kind: :rpc_request, args: %{label: "X"}, body: []})
    data = %{foo: :bar}

    expect(FarmbotOS.Celery.Scheduler, :schedule, 1, fn actual_ast,
                                                        actual_at,
                                                        actual_data ->
      assert actual_ast == ast
      assert actual_at == at
      assert actual_data == data
      :ok
    end)

    assert :ok == FarmbotOS.Celery.schedule(ast, at, data)
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

    expect(Stubs, :move_absolute, 1, fn _x, _y, _z, _s ->
      :ok
    end)

    capture_log(fn ->
      result = FarmbotOS.Celery.execute(sequence_ast, me)
      assert :ok == result
    end) =~ "[error] CeleryScript syscall stubbed: log"
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

    expect(Stubs, :read_pin, 1, fn _, _ -> {:error, "failed to read pin!"} end)
    result = FarmbotOS.Celery.execute(execute_ast, execute_ast)
    assert {:error, "failed to read pin!"} = result

    assert_receive {:csvm_done, ^execute_ast, {:error, "failed to read pin!"}}
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

    expect(Stubs, :read_pin, fn _, _ ->
      raise("big oops")
    end)

    io =
      capture_log(fn ->
        assert {:error, "big oops"} ==
                 FarmbotOS.Celery.execute(execute_ast, execute_ast)
      end)

    assert io =~ "CeleryScript Exception"
    assert_receive {:csvm_done, ^execute_ast, {:error, "big oops"}}
  end
end
