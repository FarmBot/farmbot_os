defmodule Csvm.InstructionTest do
  alias Csvm.{AST, FarmProc}

  defmacro io_test(kind) do
    kind_atom = String.to_atom(kind)

    quote do
      test unquote(kind) do
        pid = self()

        fun = fn ast ->
          send(pid, ast)
          :ok
        end

        heap =
          AST.new(unquote(kind_atom), %{}, [])
          |> AST.slice()

        step0 = FarmProc.new(fun, addr(0), heap)
        step1 = FarmProc.step(step0)
        assert FarmProc.get_status(step1) == :waiting
        step2 = FarmProc.step(step1)
        assert FarmProc.get_status(step2) == :ok
        step3 = FarmProc.step(step2)
        assert FarmProc.get_status(step3) == :done
        assert_received %AST{kind: unquote(kind_atom), args: %{}}
      end
    end
  end
end

defmodule Csvm.InstructionSetTest do
  use ExUnit.Case
  alias Csvm.{AST, FarmProc, Error}
  import Csvm.Utils
  import Csvm.InstructionTest

  @fixture AST.decode(%{
             kind: :_if,
             args: %{
               lhs: :x,
               op: "is",
               rhs: 10,
               _then: %{kind: :nothing, args: %{}},
               _else: %{kind: :nothing, args: %{}}
             }
           })

  io_test("write_pin")
  io_test("read_pin")
  io_test("set_servo_angle")
  io_test("send_message")
  io_test("move_relative")
  io_test("home")
  io_test("find_home")
  io_test("wait")
  io_test("toggle_pin")
  io_test("execute_script")
  io_test("zero")
  io_test("calibrate")
  io_test("take_photo")
  io_test("config_update")
  io_test("set_user_env")
  io_test("install_first_party_farmware")
  io_test("install_farmware")
  io_test("uninstall_farmware")
  io_test("update_farmware")
  io_test("read_status")
  io_test("sync")
  io_test("power_off")
  io_test("reboot")
  io_test("factory_reset")
  io_test("change_ownership")
  io_test("check_updates")
  io_test("dump_info")

  test "nothing returns or sets status" do
    seq_1 =
      AST.new(:sequence, %{}, [
        AST.new(:execute, %{sequence_id: 2}, []),
        AST.new(:wait, %{milliseconds: 10}, [])
      ])

    seq_2 = AST.new(:sequence, %{}, [AST.new(:execute, %{sequence_id: 3}, [])])
    seq_3 = AST.new(:sequence, %{}, [AST.new(:wait, %{milliseconds: 10}, [])])

    pid = self()

    fun = fn ast ->
      case ast do
        %{kind: :execute, args: %{sequence_id: 2}} ->
          send(pid, {:execute, 2})
          {:ok, seq_2}

        %{kind: :execute, args: %{sequence_id: 3}} ->
          send(pid, {:execute, 3})
          {:ok, seq_3}

        %{kind: :wait} ->
          send(pid, :wait)
          :ok
      end
    end

    proc0 = FarmProc.new(fun, addr(1), AST.slice(seq_1))

    complete =
      Enum.reduce(0..100, proc0, fn _, proc ->
        FarmProc.step(proc)
      end)

    assert FarmProc.get_status(complete) == :done

    assert_received {:execute, 2}
    assert_received {:execute, 3}

    # we only want to execute those sequences once.
    refute_receive {:execute, 2}
    refute_receive {:execute, 3}

    # Execute wait twice.
    assert_received :wait
    assert_received :wait
    refute_receive :wait
  end

  test "Sets the correct `crash_reason`" do
    fun = fn _ -> {:error, "whatever"} end
    heap = AST.slice(@fixture)
    farm_proc = FarmProc.new(fun, Address.new(1), heap)

    waiting = FarmProc.step(farm_proc)
    assert FarmProc.get_status(waiting) == :waiting

    crashed = FarmProc.step(waiting)
    assert FarmProc.get_status(crashed) == :crashed
    assert FarmProc.get_crash_reason(crashed) == "whatever"
  end

  test "_if handles bad interaction layer implementations" do
    fun = fn _ -> :ok end
    heap = AST.slice(@fixture)
    farm_proc = FarmProc.new(fun, Address.new(1), heap)

    assert_raise Error, "Bad _if implementation.", fn ->
      %{status: :waiting} = farm_proc = FarmProc.step(farm_proc)
      FarmProc.step(farm_proc)
    end
  end

  test "move absolute bad implementation" do
    zero00 = AST.new(:location, %{x: 0, y: 0, z: 0}, [])
    fun = fn _ -> :blah end

    heap =
      AST.new(:move_absolute, %{location: zero00, offset: zero00}, [])
      |> AST.slice()

    proc = FarmProc.new(fun, Address.new(0), heap)

    assert_raise(Error, "Bad return value: :blah", fn ->
      Enum.reduce(0..100, proc, fn _num, acc ->
        FarmProc.step(acc)
      end)
    end)

    fun2 = fn _ -> {:error, "whatever"} end
    proc2 = FarmProc.new(fun2, Address.new(0), heap)

    result =
      Enum.reduce(0..1, proc2, fn _num, acc ->
        FarmProc.step(acc)
      end)

    assert(FarmProc.get_status(result) == :crashed)
    assert(FarmProc.get_crash_reason(result) == "whatever")
  end

  test "execute handles bad interaction layer implementation." do
    fun = fn _ -> {:ok, :not_ast} end
    ast = AST.new(:execute, %{sequence_id: 100}, [])
    heap = AST.slice(ast)
    farm_proc = FarmProc.new(fun, Address.new(1), heap)

    assert_raise Error, "Bad execute implementation.", fn ->
      %{status: :waiting} = farm_proc = FarmProc.step(farm_proc)
      FarmProc.step(farm_proc)
    end
  end
end
