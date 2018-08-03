defmodule Csvm.ProcStorageTest do
  use ExUnit.Case
  alias Csvm.{ProcStorage, FarmProc}

  test "inserts farm_proc" do
    storage = ProcStorage.new(self())
    data = %FarmProc{ref: make_ref()}
    indx = ProcStorage.insert(storage, data)
    assert ProcStorage.current_index(storage) == indx
    assert ProcStorage.lookup(storage, indx) == data
  end

  test "updates a farm_proc" do
    storage = ProcStorage.new(self())
    data = %FarmProc{ref: make_ref()}
    indx = ProcStorage.insert(storage, data)
    ProcStorage.update(storage, fn ^data -> %{data | ref: make_ref()} end)
    assert ProcStorage.lookup(storage, indx) != data
  end

  test "deletes a farm_proc" do
    storage = ProcStorage.new(self())
    data = %FarmProc{ref: make_ref()}
    indx = ProcStorage.insert(storage, data)
    ProcStorage.delete(storage, indx)
    refute ProcStorage.lookup(storage, indx)
    pid = self()
    # When there is no farm_procs in the circle buffer, we get a noop.
    ProcStorage.update(storage, fn data -> send(pid, data) end)
    assert_received :noop
  end
end
