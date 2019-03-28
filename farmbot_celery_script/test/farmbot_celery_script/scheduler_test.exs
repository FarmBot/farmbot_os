defmodule FarmbotCeleryScript.SchedulerTest do
  use ExUnit.Case, async: false
  alias FarmbotCeleryScript.{Scheduler, Compiler, AST}
  alias Farmbot.TestSupport.CeleryScript.TestSysCalls

  setup do
    {:ok, shim} = TestSysCalls.checkout()
    {:ok, sch} = Scheduler.start_link([], [])
    [shim: shim, sch: sch]
  end

  test "uses default values when no parameter is found", %{sch: sch} do
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

    executed = Compiler.compile(sequence_ast)
    me = self()

    :ok =
      TestSysCalls.handle(TestSysCalls, fn
        :move_absolute, args ->
          send(me, {:move_absolute, args})
          :ok

        :coordinate, [x, y, z] ->
          %{x: x, y: y, z: z}
      end)

    {:ok, execute_ref} = Scheduler.schedule(sch, executed)
    assert_receive {Scheduler, ^execute_ref, :ok}
    assert_receive {:move_absolute, [129, 129, 129, 921]}
  end

  test "syscall errors", %{sch: sch} do
    execute_ast =
      %{
        kind: :rpc_request,
        args: %{label: "hello world"},
        body: [
          %{kind: :read_pin, args: %{pin_number: 1, pin_mode: 0}}
        ]
      }
      |> AST.decode()

    executed = Compiler.compile(execute_ast)

    :ok =
      TestSysCalls.handle(TestSysCalls, fn
        :read_pin, _ -> {:error, "failed to read pin!"}
      end)

    {:ok, execute_ref} = Scheduler.schedule(sch, executed)
    assert_receive {Scheduler, ^execute_ref, {:error, "failed to read pin!"}}
  end

  @tag :annoying
  test "regular exceptions still occur", %{sch: sch} do
    Process.flag(:trap_exit, true)

    execute_ast =
      %{
        kind: :rpc_request,
        args: %{label: "hello world"},
        body: [
          %{kind: :read_pin, args: %{pin_number: 1, pin_mode: 0}}
        ]
      }
      |> AST.decode()

    # {:ok, execute_ref} = Scheduler.schedule(sch, executed)
    # refute_receive {Scheduler, ^execute_ref, {:error, "failed to read pin!"}}
    # assert_receive {:EXIT, ^sch, _}

    executed = Compiler.compile(execute_ast)

    :ok =
      TestSysCalls.handle(TestSysCalls, fn
        :read_pin, _ -> raise("failed to read pin!")
      end)

    {:ok, execute_ref} = Scheduler.execute(sch, executed)
    refute_receive {Scheduler, ^execute_ref, {:error, "failed to read pin!"}}
    assert_receive {:EXIT, ^sch, _}, 1000
  end

  test "executing a sequence on top of a scheduled sequence", %{sch: sch} do
    scheduled_ast =
      %{
        kind: :sequence,
        args: %{locals: %{kind: :variable_declaration, args: %{}}},
        body: [
          %{kind: :wait, args: %{milliseconds: 2000}},
          %{kind: :write_pin, args: %{pin_number: 1, pin_mode: 0, pin_value: 1}}
        ]
      }
      |> AST.decode()

    scheduled = Compiler.compile(scheduled_ast)

    execute_ast =
      %{
        kind: :rpc_request,
        args: %{label: "hello world"},
        body: [
          %{kind: :read_pin, args: %{pin_number: 1, pin_mode: 0}}
        ]
      }
      |> AST.decode()

    executed = Compiler.compile(execute_ast)

    pid = self()

    :ok =
      TestSysCalls.handle(TestSysCalls, fn
        :wait, [millis] ->
          send(pid, {:wait, :os.system_time()})
          Process.sleep(millis)

        :write_pin, _ ->
          send(pid, {:write_pin, :os.system_time()})
          :ok

        :read_pin, _ ->
          send(pid, {:read_pin, :os.system_time()})
          1
      end)

    {:ok, scheduled_ref} = Scheduler.schedule(sch, scheduled)
    {:ok, execute_ref} = Scheduler.schedule(sch, executed)

    assert_receive {Scheduler, ^scheduled_ref, :ok}, 5_000
    assert_receive {Scheduler, ^execute_ref, :ok}, 5_000

    assert_receive {:wait, time_1}
    assert_receive {:read_pin, time_2}
    assert_receive {:write_pin, time_3}

    assert [^time_1, ^time_3, ^time_2] = Enum.sort([time_1, time_2, time_3], &(&1 <= &2))
  end

  test "execute twice", %{sch: sch} do
    execute_ast_1 =
      %{
        kind: :rpc_request,
        args: %{label: "hello world 1"},
        body: [
          %{kind: :wait, args: %{milliseconds: 1000}}
        ]
      }
      |> AST.decode()

    execute_ast_2 =
      %{
        kind: :rpc_request,
        args: %{label: "hello world 2"},
        body: [
          %{kind: :read_pin, args: %{pin_number: 1, pin_mode: 0}}
        ]
      }
      |> AST.decode()

    execute_1 = Compiler.compile(execute_ast_1)
    execute_2 = Compiler.compile(execute_ast_2)

    pid = self()

    :ok =
      TestSysCalls.handle(TestSysCalls, fn
        :wait, [millis] ->
          send(pid, {:wait, :os.system_time()})
          Process.sleep(millis)

        :read_pin, _ ->
          send(pid, {:read_pin, :os.system_time()})
          1
      end)

    task_1 =
      Task.async(fn ->
        {:ok, execute_ref_1} = Scheduler.execute(sch, execute_1)
        assert_receive {Scheduler, ^execute_ref_1, :ok}, 3000
      end)

    task_2 =
      Task.async(fn ->
        {:ok, execute_ref_2} = Scheduler.execute(sch, execute_2)
        assert_receive {Scheduler, ^execute_ref_2, :ok}, 3000
      end)

    _ = Task.await(task_1)
    _ = Task.await(task_2)

    assert_receive {:wait, time_1}
    assert_receive {:read_pin, time_2}

    assert time_2 >= time_1 + 1000
  end

  test "execute then schedule", %{sch: sch} do
    execute_ast_1 =
      %{
        kind: :rpc_request,
        args: %{label: "hello world 1"},
        body: [
          %{kind: :wait, args: %{milliseconds: 1000}}
        ]
      }
      |> AST.decode()

    schedule_ast_1 =
      %{
        kind: :sequence,
        args: %{locals: %{kind: :variable_declaration, args: %{}}},
        body: [
          %{kind: :read_pin, args: %{pin_number: 1, pin_mode: 0}}
        ]
      }
      |> AST.decode()

    execute_1 = Compiler.compile(execute_ast_1)
    schedule_1 = Compiler.compile(schedule_ast_1)

    pid = self()

    :ok =
      TestSysCalls.handle(TestSysCalls, fn
        :wait, [millis] ->
          send(pid, {:wait, :os.system_time()})
          Process.sleep(millis)

        :read_pin, _ ->
          send(pid, {:read_pin, :os.system_time()})
          1
      end)

    task_1 =
      Task.async(fn ->
        {:ok, execute_ref_1} = Scheduler.execute(sch, execute_1)
        assert_receive {Scheduler, ^execute_ref_1, :ok}, 3000
      end)

    task_2 =
      Task.async(fn ->
        {:ok, execute_ref_2} = Scheduler.execute(sch, schedule_1)
        assert_receive {Scheduler, ^execute_ref_2, :ok}, 3000
      end)

    _ = Task.await(task_1)
    _ = Task.await(task_2)

    assert_receive {:wait, time_1}
    assert_receive {:read_pin, time_2}

    # Assert that the read pin didn't execute until the wait is complete
    assert time_2 >= time_1 + 1000
  end

  test "schedule and execute simultaneously", %{sch: sch} do
    schedule_ast_1 =
      %{
        kind: :sequence,
        args: %{locals: %{kind: :variable_declaration, args: %{}}},
        body: [
          %{kind: :wait, args: %{milliseconds: 2500}}
        ]
      }
      |> AST.decode()

    execute_ast_1 =
      %{
        kind: :rpc_request,
        args: %{label: "hello world 1"},
        body: [
          %{kind: :read_pin, args: %{pin_number: 1, pin_mode: 0}}
        ]
      }
      |> AST.decode()

    schedule_1 = Compiler.compile(schedule_ast_1)
    execute_1 = Compiler.compile(execute_ast_1)

    pid = self()

    :ok =
      TestSysCalls.handle(TestSysCalls, fn
        :wait, [millis] ->
          send(pid, {:wait, :os.system_time()})
          Process.sleep(millis)

        :read_pin, _ ->
          send(pid, {:read_pin, :os.system_time()})
          1
      end)

    task_1 =
      Task.async(fn ->
        {:ok, schedule_ref_1} = Scheduler.schedule(sch, schedule_1)
        # TODO(Connor) Literally any function call will
        # make this not a race condition???
        IO.inspect(schedule_ref_1, label: "task_1")
        assert_receive {Scheduler, ^schedule_ref_1, :ok}, 3000
      end)

    task_2 =
      Task.async(fn ->
        {:ok, execute_ref_1} = Scheduler.execute(sch, execute_1)
        IO.inspect(execute_ref_1, label: "task_2")
        assert_receive {Scheduler, ^execute_ref_1, :ok}, 3000
      end)

    _ = Task.await(task_1)
    _ = Task.await(task_2)

    assert_receive {:wait, time_1}
    assert_receive {:read_pin, time_2}

    # Assert that the read pin executed and finished before the wait.
    assert time_2 <= time_1 + 2500
  end
end
