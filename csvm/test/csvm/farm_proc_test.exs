defmodule Csvm.FarmProcTest do
  use ExUnit.Case
  alias Csvm.{AST, FarmProc, Error}
  import Csvm.Utils

  test "inspects farm_proc" do
    heap = Csvm.TestSupport.Fixtures.heap()
    farm_proc = FarmProc.new(fn _ -> :ok end, addr(0), heap)
    assert inspect(farm_proc) == "#FarmProc<[ok] #Pointer<0, 1>>"
  end

  test "init a new farm_proc" do
    fun = fn _ast ->
      :ok
    end

    heap = Csvm.TestSupport.Fixtures.heap()
    farm_proc = FarmProc.new(fun, addr(0), heap)

    assert FarmProc.get_pc_ptr(farm_proc) == Pointer.new(addr(0), addr(1))

    assert FarmProc.get_heap_by_page_index(farm_proc, addr(0)) == heap
    assert FarmProc.get_return_stack(farm_proc) == []

    assert FarmProc.get_kind(
             farm_proc,
             FarmProc.get_pc_ptr(farm_proc)
           ) == :sequence
  end

  test "IO functions require 2 steps" do
    fun = fn _ast -> :ok end

    heap =
      AST.new(:move_relative, %{x: 1, y: 2, z: 3}, [])
      |> AST.Slicer.run()

    step0 = FarmProc.new(fun, addr(1), heap)
    assert FarmProc.get_status(step0) == :ok

    # Step into the `move_relative` block.
    # step1: waiting for IO to complete async.
    step1 = FarmProc.step(step0)
    assert FarmProc.get_status(step1) == :waiting

    # step2: IO is _probably_ completed by now. Complete the step.
    # This is _technically_ a race condition, but it shouldn't fail in this case
    step2 = FarmProc.step(step1)
    assert FarmProc.get_status(step2) == :ok
  end

  test "io functions crash the vm" do
    fun = fn _ -> {:error, "movement error"} end

    heap =
      AST.new(:move_relative, %{x: 100, y: 123, z: 0}, [])
      |> Csvm.AST.Slicer.run()

    step0 = FarmProc.new(fun, addr(0), heap)
    step1 = FarmProc.step(step0)
    assert FarmProc.get_pc_ptr(step1).page_address == addr(0)
    assert FarmProc.get_status(step1) == :waiting
    step2 = FarmProc.step(step1)
    assert FarmProc.get_status(step2) == :crashed

    assert FarmProc.get_pc_ptr(step2) ==
             Pointer.null(FarmProc.get_zero_page(step1))
  end

  test "io functions bad return values raise Csvm.Error exception" do
    fun = fn _ -> {:eroror, 100} end

    heap =
      AST.new(:move_relative, %{x: 100, y: 123, z: 0}, [])
      |> Csvm.AST.Slicer.run()

    step0 = FarmProc.new(fun, addr(0), heap)
    step1 = FarmProc.step(step0)
    assert FarmProc.get_status(step1) == :waiting
    assert Process.alive?(step1.io_latch)

    assert_raise Error,
                 "Bad return value: {:eroror, 100}",
                 fn ->
                   assert Process.alive?(step1.io_latch)
                   FarmProc.step(step1)
                 end
  end

  test "get_body_address" do
    farm_proc =
      FarmProc.new(
        fn _ -> :ok end,
        addr(0),
        Csvm.TestSupport.Fixtures.heap()
      )

    data =
      FarmProc.get_body_address(
        farm_proc,
        Pointer.new(addr(0), addr(1))
      )

    refute FarmProc.is_null_address?(data)
  end

  test "null address" do
    farm_proc =
      FarmProc.new(
        fn _ -> :ok end,
        addr(0),
        Csvm.TestSupport.Fixtures.heap()
      )

    assert FarmProc.is_null_address?(
             Pointer.null(FarmProc.get_zero_page(farm_proc))
           )

    assert FarmProc.is_null_address?(Address.null())
    assert FarmProc.is_null_address?(Pointer.new(addr(0), addr(0)))
    assert FarmProc.is_null_address?(addr(0))
    assert FarmProc.is_null_address?(Pointer.new(addr(100), addr(0)))
    assert FarmProc.is_null_address?(ptr(100, 0))
    refute FarmProc.is_null_address?(ptr(100, 99))
    refute FarmProc.is_null_address?(Pointer.new(addr(100), addr(50)))
    refute FarmProc.is_null_address?(addr(99))
  end

  test "performs all the steps" do
    this = self()

    fun = fn ast ->
      send(this, ast)
      :ok
    end

    step0 = FarmProc.new(fun, addr(2), Csvm.TestSupport.Fixtures.heap())

    assert FarmProc.get_kind(step0, FarmProc.get_pc_ptr(step0)) == :sequence

    %FarmProc{} = step1 = FarmProc.step(step0)
    assert Enum.count(FarmProc.get_return_stack(step1)) == 1
    assert FarmProc.get_status(step1) == :ok

    pc_pointer = FarmProc.get_pc_ptr(step1)
    actual_kind = FarmProc.get_kind(step1, pc_pointer)
    step1_cell = FarmProc.get_cell_by_address(step1, pc_pointer)
    assert actual_kind == :move_absolute
    assert step1_cell[:speed] == 100

    # Perform "move_abs" pt1
    %FarmProc{} = step2 = FarmProc.step(step1)
    assert FarmProc.get_status(step2) == :waiting

    # Perform "move_abs" pt2
    %FarmProc{} = step3 = FarmProc.step(step2)
    assert FarmProc.get_status(step3) == :ok

    # Make sure side effects are called
    pc_pointer = FarmProc.get_pc_ptr(step3)
    actual_kind = FarmProc.get_kind(step3, pc_pointer)
    step3_cell = FarmProc.get_cell_by_address(step3, pc_pointer)
    assert actual_kind == :move_relative
    assert step3_cell[:x] == 10
    assert step3_cell[:y] == 20
    assert step3_cell[:z] == 30
    assert step3_cell[:speed] == 50
    # Test side effects.

    assert_receive %Csvm.AST{
      args: %{
        location: %Csvm.AST{
          args: %{pointer_id: 1, pointer_type: "Plant"},
          kind: :point
        },
        offset: %Csvm.AST{
          args: %{x: 10, y: 20, z: -30},
          kind: :coordinate
        },
        speed: 100
      },
      kind: :move_absolute
    }

    # Perform "move_rel" pt1
    %FarmProc{} = step4 = FarmProc.step(step3)
    assert FarmProc.get_status(step4) == :waiting

    # Perform "move_rel" pt2
    %FarmProc{} = step5 = FarmProc.step(step4)
    assert FarmProc.get_status(step5) == :ok

    assert_receive %Csvm.AST{
      kind: :move_relative,
      comment: nil,
      args: %{
        x: 10,
        y: 20,
        z: 30,
        speed: 50
      }
    }

    # Perform "write_pin" pt1
    %FarmProc{} = step6 = FarmProc.step(step5)
    assert FarmProc.get_status(step6) == :waiting

    # Perform "write_pin" pt2
    %FarmProc{} = step7 = FarmProc.step(step6)
    assert FarmProc.get_status(step7) == :ok

    assert_receive %Csvm.AST{
      kind: :write_pin,
      args: %{
        pin_number: 0,
        pin_value: 0,
        pin_mode: 0
      }
    }

    # Perform "write_pin" pt1
    %FarmProc{} = step8 = FarmProc.step(step7)
    assert FarmProc.get_status(step8) == :waiting

    # Perform "write_pin" pt2
    %FarmProc{} = step9 = FarmProc.step(step8)
    assert FarmProc.get_status(step9) == :ok

    assert_receive %Csvm.AST{
      kind: :write_pin,
      args: %{
        pin_mode: 0,
        pin_value: 1,
        pin_number: %Csvm.AST{
          kind: :named_pin,
          args: %{
            pin_type: "Peripheral",
            pin_id: 5
          }
        }
      }
    }

    # Perform "read_pin" pt1
    %FarmProc{} = step10 = FarmProc.step(step9)
    assert FarmProc.get_status(step10) == :waiting

    # Perform "read_pin" pt2
    %FarmProc{} = step11 = FarmProc.step(step10)
    assert FarmProc.get_status(step11) == :ok

    assert_receive %Csvm.AST{
      kind: :read_pin,
      args: %{
        pin_mode: 0,
        label: "---",
        pin_number: 0
      }
    }

    # Perform "read_pin" pt1
    %FarmProc{} = step12 = FarmProc.step(step11)
    assert FarmProc.get_status(step12) == :waiting

    # Perform "read_pin" pt2
    %FarmProc{} = step13 = FarmProc.step(step12)
    assert FarmProc.get_status(step13) == :ok

    assert_receive %Csvm.AST{
      kind: :read_pin,
      args: %{
        pin_mode: 1,
        label: "---",
        pin_number: %Csvm.AST{
          kind: :named_pin,
          args: %{
            pin_type: "Sensor",
            pin_id: 1
          }
        }
      }
    }

    # Perform "read_pin" pt1
    %FarmProc{} = step14 = FarmProc.step(step13)
    assert FarmProc.get_status(step14) == :waiting

    # Perform "read_pin" pt2
    %FarmProc{} = step15 = FarmProc.step(step14)
    assert FarmProc.get_status(step15) == :ok

    assert_receive %Csvm.AST{
      kind: :wait,
      args: %{
        milliseconds: 100
      }
    }

    # Perform "send_message" pt1
    %FarmProc{} = step16 = FarmProc.step(step15)
    assert FarmProc.get_status(step16) == :waiting

    # Perform "send_message" pt2
    %FarmProc{} = step17 = FarmProc.step(step16)
    assert FarmProc.get_status(step17) == :ok

    assert_receive %Csvm.AST{
      kind: :send_message,
      args: %{
        message: "FarmBot is at position {{ x }}, {{ y }}, {{ z }}.",
        message_type: "success"
      },
      body: [
        %Csvm.AST{kind: :channel, args: %{channel_name: "toast"}},
        %Csvm.AST{kind: :channel, args: %{channel_name: "email"}},
        %Csvm.AST{kind: :channel, args: %{channel_name: "espeak"}}
      ]
    }

    # Perform "find_home" pt1
    %FarmProc{} = step18 = FarmProc.step(step17)
    assert FarmProc.get_status(step18) == :waiting

    # Perform "find_home" pt2
    %FarmProc{} = step19 = FarmProc.step(step18)
    assert FarmProc.get_status(step19) == :ok

    assert_receive %Csvm.AST{
      kind: :find_home,
      args: %{
        speed: 100,
        axis: "all"
      }
    }
  end

  test "nonrecursive execute" do
    seq2 =
      AST.new(:sequence, %{}, [
        AST.new(:wait, %{milliseconds: 100}, [])
      ])

    main_seq =
      AST.new(:sequence, %{}, [
        AST.new(:execute, %{sequence_id: 2}, [])
      ])

    initial_heap = AST.Slicer.run(main_seq)

    fun = fn ast ->
      if ast.kind == :execute do
        {:ok, seq2}
      else
        :ok
      end
    end

    step0 = FarmProc.new(fun, addr(1), initial_heap)
    assert FarmProc.get_heap_by_page_index(step0, addr(1))
    assert FarmProc.get_status(step0) == :ok

    assert_raise Error, ~r(page), fn ->
      FarmProc.get_heap_by_page_index(step0, addr(2))
    end

    # enter sequence.
    step1 = FarmProc.step(step0)
    assert FarmProc.get_status(step1) == :ok

    # enter execute.
    step2 = FarmProc.step(step1)
    assert FarmProc.get_status(step2) == :waiting

    # Finish execute.
    step2 = FarmProc.step(step2)
    assert FarmProc.get_status(step2) == :ok

    assert FarmProc.get_heap_by_page_index(step2, addr(2))
    [ptr1, ptr2] = FarmProc.get_return_stack(step2)
    assert ptr1 == Pointer.new(addr(1), addr(0))
    assert ptr2 == Pointer.new(addr(1), addr(0))

    # start sequence
    step3 = FarmProc.step(step2)
    assert FarmProc.get_status(step3) == :ok

    [ptr3 | _] = FarmProc.get_return_stack(step3)
    assert ptr3 == Pointer.new(addr(2), addr(0))

    step4 = FarmProc.step(step3)
    assert FarmProc.get_status(step4) == :waiting

    step5 = FarmProc.step(step4)
    step6 = FarmProc.step(step5)
    step7 = FarmProc.step(step6)
    assert FarmProc.get_return_stack(step7) == []

    assert FarmProc.get_pc_ptr(step7) ==
             Pointer.null(FarmProc.get_zero_page(step7))
  end

  test "raises when trying to step thru a crashed proc" do
    heap = AST.new(:execute, %{sequence_id: 100}, []) |> AST.Slicer.run()

    fun = fn _ -> {:error, "could not find sequence"} end
    step0 = FarmProc.new(fun, addr(1), heap)
    waiting = FarmProc.step(step0)
    crashed = FarmProc.step(waiting)
    assert FarmProc.get_status(crashed) == :crashed

    assert_raise Error,
                 "Tried to step with crashed process!",
                 fn ->
                   FarmProc.step(crashed)
                 end
  end

  test "recursive sequence" do
    sequence_5 =
      AST.new(:sequence, %{}, [
        AST.new(:execute, %{sequence_id: 5}, [])
      ])

    fun = fn ast ->
      if ast.kind == :execute do
        {:error, "Should already be cached."}
      else
        :ok
      end
    end

    heap = AST.Slicer.run(sequence_5)
    step0 = FarmProc.new(fun, addr(5), heap)

    step1 = FarmProc.step(step0)
    assert Enum.count(FarmProc.get_return_stack(step1)) == 1

    step2 = FarmProc.step(step1)
    assert Enum.count(FarmProc.get_return_stack(step2)) == 2

    step3 = FarmProc.step(step2)
    assert Enum.count(FarmProc.get_return_stack(step3)) == 3

    pc = FarmProc.get_pc_ptr(step3)
    zero_page_num = FarmProc.get_zero_page(step3)
    assert pc.page_address == zero_page_num

    step999 =
      Enum.reduce(0..996, step3, fn _, acc ->
        FarmProc.step(acc)
      end)

    assert_raise Error, "Too many reductions!", fn ->
      FarmProc.step(step999)
    end
  end

  test "raises an exception when no implementation is found for a `kind`" do
    heap =
      AST.new(:sequence, %{}, [AST.new(:fire_laser, %{}, [])])
      |> Csvm.AST.Slicer.run()

    assert_raise Error,
                 "No implementation for: fire_laser",
                 fn ->
                   step_0 = FarmProc.new(fn _ -> :ok end, addr(0), heap)

                   step_1 = FarmProc.step(step_0)
                   _step_2 = FarmProc.step(step_1)
                 end
  end

  test "sequence with no body halts" do
    heap = AST.new(:sequence, %{}, []) |> Csvm.AST.Slicer.run()
    farm_proc = FarmProc.new(fn _ -> :ok end, addr(0), heap)
    assert FarmProc.get_status(farm_proc) == :ok

    # step into the sequence.
    next = FarmProc.step(farm_proc)

    assert FarmProc.get_pc_ptr(next) ==
             Pointer.null(FarmProc.get_zero_page(next))

    assert FarmProc.get_return_stack(next) == []

    # Each following step should still be stopped/paused.
    next1 = FarmProc.step(next)

    assert FarmProc.get_pc_ptr(next1) ==
             Pointer.null(FarmProc.get_zero_page(next1))

    assert FarmProc.get_return_stack(next1) == []

    next2 = FarmProc.step(next1)

    assert FarmProc.get_pc_ptr(next2) ==
             Pointer.null(FarmProc.get_zero_page(next2))

    assert FarmProc.get_return_stack(next2) == []

    next3 = FarmProc.step(next2)

    assert FarmProc.get_pc_ptr(next3) ==
             Pointer.null(FarmProc.get_zero_page(next3))

    assert FarmProc.get_return_stack(next3) == []
  end

  test "_if" do
    pid = self()

    fun_gen = fn bool ->
      fn ast ->
        if ast.kind == :_if do
          send(pid, bool)
          {:ok, bool}
        else
          :ok
        end
      end
    end

    nothing_ast = AST.new(:nothing, %{}, [])

    heap =
      AST.new(
        :_if,
        %{
          rhs: 0,
          op: "is_undefined",
          lhs: "x",
          _then: nothing_ast,
          _else: nothing_ast
        },
        []
      )
      |> AST.Slicer.run()

    truthy_step0 = FarmProc.new(fun_gen.(true), addr(1), heap)
    truthy_step1 = FarmProc.step(truthy_step0)
    assert FarmProc.get_status(truthy_step1) == :waiting
    truthy_step2 = FarmProc.step(truthy_step1)
    assert FarmProc.get_status(truthy_step2) == :ok
    assert_received true

    falsy_step0 = FarmProc.new(fun_gen.(false), addr(1), heap)
    falsy_step1 = FarmProc.step(falsy_step0)
    assert FarmProc.get_status(falsy_step1) == :waiting
    falsy_step2 = FarmProc.step(falsy_step1)
    assert FarmProc.get_status(falsy_step2) == :ok
    assert_received false
  end

  test "IO isn't instant" do
    sleep_time = 100

    fun = fn _move_relative_ast ->
      Process.sleep(sleep_time)
      :ok
    end

    heap =
      AST.new(:move_relative, %{x: 1, y: 2, z: 0}, [])
      |> AST.Slicer.run()

    step0 = FarmProc.new(fun, addr(1), heap)

    step1 = FarmProc.step(step0)
    step2 = FarmProc.step(step1)
    assert FarmProc.get_status(step1) == :waiting
    assert FarmProc.get_status(step2) == :waiting
    Process.sleep(sleep_time)
    final = FarmProc.step(step2)
    assert FarmProc.get_status(final) == :ok
  end

  test "get_cell_attr missing attr raises" do
    fun = fn _ -> :ok end
    heap = ast(:wait, %{milliseconds: 123}) |> AST.slice()
    farm_proc = FarmProc.new(fun, addr(1), heap)
    pc_ptr = FarmProc.get_pc_ptr(farm_proc)
    assert FarmProc.get_cell_attr(farm_proc, pc_ptr, :milliseconds) == 123

    assert_raise Error, "no field called: macroseconds at #Pointer<1, 1>", fn ->
      FarmProc.get_cell_attr(farm_proc, pc_ptr, :macroseconds)
    end
  end

  test "get_cell_by_address raises if no cell at address" do
    fun = fn _ -> :ok end
    heap = ast(:wait, %{milliseconds: 123}) |> AST.slice()
    farm_proc = FarmProc.new(fun, addr(1), heap)

    assert_raise Error, "bad address", fn ->
      FarmProc.get_cell_by_address(farm_proc, ptr(1, 200))
    end
  end
end
