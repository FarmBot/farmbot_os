defmodule Farmbot.CeleryScript.RunTime.FarmwareTest do
  use ExUnit.Case
  alias Farmbot.CeleryScript.AST
  alias Farmbot.CeleryScript.RunTime.FarmProc
  import Farmbot.CeleryScript.Utils

  @execute_farmware_fixture %{
    kind: :execute_script,
    args: %{package: "test-farmware"}
  }

  @rpc_request %{
    kind: :rpc_request,
    args: %{label: "test-farmware-rpc"},
    body: [
      @execute_farmware_fixture
    ]
  }

  test "farmware" do
    pid = self()
    {:ok, agent} = Agent.start_link(fn -> 0 end)

    fun = fn ast ->
      case ast.kind do
        :execute_script ->
          case Agent.get_and_update(agent, fn state -> {state, state + 1} end) do
            0 -> {:ok, ast(:wait, %{milliseconds: 123})}
            1 -> {:ok, ast(:wait, %{milliseconds: 456})}
            2 -> :ok
          end

        :wait ->
          send(pid, ast)
          :ok
      end
    end

    heap =
      @rpc_request
      |> AST.decode()
      |> AST.slice()

    %FarmProc{} = step0 = FarmProc.new(fun, addr(-1), heap)

    complete =
      Enum.reduce(0..200, step0, fn _, proc ->
        %FarmProc{} = wait_for_io(proc)
      end)

    assert complete.status == :done

    assert_receive %AST{kind: :wait, args: %{milliseconds: 123}}
    assert_receive %AST{kind: :wait, args: %{milliseconds: 456}}
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
