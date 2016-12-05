defmodule Sequence.InstructionSet_0Test do
  use ExUnit.Case, async: true
  defmodule Parent do
    use GenServer

    def start_link() do
      GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end

    def init([]) do
      {:ok, []}
    end
  end

  setup_all do
    {:ok, par} = Parent.start_link
    {:ok, sis} = Sequence.InstructionSet_0.start_link(Parent)
    {:ok, %{parent: par, sis: sis}}
  end

  test "starts instruction set", context do
    par = context[:parent]
    sis = context[:sis]
    assert(is_pid(par) == true)
    assert(is_pid(sis) == true)    
  end
end
