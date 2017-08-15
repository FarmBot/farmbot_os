defmodule Farmbot.BotState.Lib.PartitionTest do
  @moduledoc "Tests common functionality for bot state partitions."

  use ExUnit.Case

  alias Farmbot.BotState.Lib.Partition

  defstruct [hello: 1, world: 1]
  test "dispatches info properly." do
    public = %__MODULE__{}
    private = %Partition.PrivateState{bot_state_tracker: self(), public: public}
    r = Partition.dispatch(private)
    assert match?({:noreply, ^private}, r)
    assert_received {:"$gen_cast", {:update, __MODULE__, ^public}}

    r = Partition.dispatch(:some_cool_result, private)
    assert match?({:reply, :some_cool_result, ^private}, r)
    assert_received {:"$gen_cast", {:update, __MODULE__, ^public}}
  end

  defmodule TestPartA do
    @moduledoc false
    defstruct [some_state_data: :default]
    use Farmbot.BotState.Lib.Partition

    def force_push(ser), do: GenServer.call(ser, :force)

    def partition_call(:force, _, pub) do
      {:reply, pub, pub}
    end
  end

  test "uses partion." do
    assert function_exported?(TestPartA, :partition_init, 1)
    assert function_exported?(TestPartA, :partition_call, 3)
    assert function_exported?(TestPartA, :partition_cast, 2)
    assert function_exported?(TestPartA, :partition_info, 2)
  end

  defmodule BotStateStub do
    use GenServer

    def start_link() do
      GenServer.start_link(__MODULE__, nil, [])
    end

    def put_test_fn(ser, fun), do: GenServer.call(ser, {:put_test_fn, fun})
    def get_res(ser), do: GenServer.call(ser, :get_res)

    def handle_call({:put_test_fn, fun}, _, _), do: {:reply, :ok, fun}
    def handle_call(:get_res, _, res),  do: {:reply, res, nil}

    def handle_cast(cast, fun) do
      {:noreply, fun.(cast)}
    end

  end

  test "ensures default behaviour." do
    {:ok, bs} =  BotStateStub.start_link()
    {:ok, pid} = TestPartA.start_link(bs, [])

    s = :sys.get_state(pid)
    pub = %TestPartA{}
    assert match?(^pub, s.public)
    assert s.bot_state_tracker == bs

    fun = fn(cast) -> cast end

    :ok = BotStateStub.put_test_fn(bs, fun)
    TestPartA.force_push(pid)
    res = BotStateStub.get_res(bs)
    assert match? {:update, TestPartA, ^pub}, res

  end
end
