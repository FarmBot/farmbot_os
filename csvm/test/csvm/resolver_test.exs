defmodule Csvm.ResolverTest do
  use ExUnit.Case, async: true
  alias Csvm.{AST, FarmProc}
  import Csvm.Utils

  def fetch_fixture(fname) do
    File.read!(fname) |> Jason.decode!() |> AST.decode()
  end

  defp io_fun(pid) do
    {:ok, agent} = Agent.start_link(fn -> 0 end)

    fn ast ->
      case ast.kind do
        :point ->
          :ok = Agent.update(agent, fn old -> old + 1 end)

          {:ok,
           AST.new(
             :coordinate,
             %{
               x: Agent.get(agent, fn data -> data end),
               y: 100,
               z: 100
             },
             []
           )}

        :wait ->
          send(pid, ast)
          :ok

        :move_absolute ->
          send(pid, ast)
          :ok

        :execute ->
          {:ok, fetch_fixture("fixture/inner_sequence.json")}
      end
    end
  end

  test "variable resolution" do
    outer_json =
      fetch_fixture("fixture/outer_sequence.json") |> AST.Slicer.run()

    farm_proc0 = FarmProc.new(io_fun(self()), addr(0), outer_json)

    farm_proc1 =
      Enum.reduce(0..120, farm_proc0, fn _num, acc ->
        wait_for_io(acc)
      end)

    assert FarmProc.get_status(farm_proc1) == :done

    assert_received %Csvm.AST{
      args: %{
        location: %Csvm.AST{
          args: %{x: 1, y: 100, z: 100},
          body: [],
          comment: nil,
          kind: :coordinate
        }
      },
      kind: :move_absolute
    }

    assert_received %Csvm.AST{
      args: %{
        location: %Csvm.AST{
          args: %{x: 2, y: 100, z: 100},
          body: [],
          comment: nil,
          kind: :coordinate
        }
      },
      kind: :move_absolute
    }

    assert_received %Csvm.AST{
      args: %{milliseconds: 1000},
      body: [],
      comment: nil,
      kind: :wait
    }

    assert_received %Csvm.AST{
      args: %{milliseconds: 1050},
      body: [],
      comment: nil,
      kind: :wait
    }
  end

  test "sequence with unbound variable" do
    unbound_json = fetch_fixture("fixture/unbound.json") |> AST.Slicer.run()

    farm_proc0 = FarmProc.new(io_fun(self()), addr(0), unbound_json)

    assert_raise Csvm.Error,
                 "unbound identifier: var20 from pc: #Pointer<0, 0>",
                 fn ->
                   Enum.reduce(0..120, farm_proc0, fn _num, acc ->
                     wait_for_io(acc)
                   end)
                 end
  end

  test "won't traverse pages" do
    fixture = File.read!("fixture/unbound_var_x.json") |> Jason.decode!()

    outter = fixture["outter"] |> AST.decode() |> AST.slice()
    inner = fixture["inner"] |> AST.decode()

    syscall = fn ast ->
      case ast.kind do
        :point ->
          {:ok, AST.new(:coordinate, %{x: 0, y: 1, z: 2}, [])}

        :move_absolute ->
          :ok

        :execute ->
          {:ok, inner}
      end
    end

    proc = FarmProc.new(syscall, addr(456), outter)

    assert_raise(
      Csvm.Error,
      "unbound identifier: x from pc: #Pointer<123, 0>",
      fn ->
        result =
          Enum.reduce(0..100, proc, fn _num, acc ->
            wait_for_io(acc)
          end)

        IO.inspect(result)
      end
    )
  end

  def wait_for_io(%FarmProc{} = farm_proc, timeout \\ 1000) do
    timer = Process.send_after(self(), :timeout, timeout)
    results = do_step(FarmProc.step(farm_proc))
    Process.cancel_timer(timer)
    results
  end

  defp do_step(%{status: :ok} = farm_proc), do: farm_proc
  defp do_step(%{status: :done} = farm_proc), do: farm_proc

  defp do_step(farm_proc) do
    receive do
      :timeout -> raise("timed out waiting for farm_proc io!")
    after
      10 -> :notimeout
    end

    FarmProc.step(farm_proc)
    |> do_step()
  end
end
