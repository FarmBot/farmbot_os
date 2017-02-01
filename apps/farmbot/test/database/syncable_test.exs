defmodule SyncableTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use Amnesia

  import Syncable
  defdatabase TestDB do
    use Amnesia
    syncable Person, [:legs, :arms]
  end

  setup_all do
    Amnesia.start
    TestDB.create! Keyword.put([], :memory, [node()])
  end

  test "gets keys for a syncable" do
    assert TestDB.Person.required_keys == [:legs, :arms]
  end

end
