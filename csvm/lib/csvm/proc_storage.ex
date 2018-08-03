defmodule Csvm.ProcStorage do
  @moduledoc """
  Process wrapper around CircularList
  """
  alias Csvm.FarmProc

  @opaque proc_storage :: pid
  @opaque index :: pos_integer

  def new(_csvm_id) do
    {:ok, agent} = Agent.start_link(&CircularList.new/0)
    agent
  end

  @spec insert(proc_storage, FarmProc.t()) :: index
  def insert(this, %FarmProc{} = farm_proc) do
    Agent.get_and_update(this, fn cl ->
      new_cl =
        cl
        |> CircularList.push(farm_proc)
        |> CircularList.rotate()

      {CircularList.get_index(new_cl), new_cl}
    end)
  end

  @spec current_index(proc_storage) :: index
  def current_index(this) do
    Agent.get(this, &CircularList.get_index(&1))
  end

  @spec lookup(proc_storage, index) :: FarmProc.t()
  def lookup(this, index) do
    Agent.get(this, &CircularList.at(&1, index))
  end

  @spec delete(proc_storage, index) :: :ok
  def delete(this, index) do
    Agent.update(this, &CircularList.remove(&1, index))
  end

  @spec update(proc_storage, (FarmProc.t() -> FarmProc.t())) :: :ok
  def update(this, fun) when is_function(fun) do
    Agent.update(this, &CircularList.update_current(&1, fun))
    Agent.update(this, &CircularList.rotate(&1))
  end
end
