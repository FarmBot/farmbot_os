defmodule Farmbot.Database.RecordStorageTest do
  @moduledoc "Test storage implementation."

  use ExUnit.Case
  alias Farmbot.Database.RecordStorage, as: RS
  alias Farmbot.Database.Syncable

  defmodule SomeSyncable do
    use Farmbot.Database.Syncable, model: [:foo, :bar], endpoint: {"fake", "nope"}
  end

  defmodule SomeOtherSyncable do
    use Farmbot.Database.Syncable, model: [:foo, :baz], endpoint: {"fake", "nope"}
  end

  setup do
    {:ok, rs} = RS.start_link([])
    [rs: rs]
  end

  test "Commits a single new record.", ctx do
    record = %SomeSyncable{foo: 1, bar: 1, id: 123}
    :ok = RS.commit_records(record, ctx.rs)
    assert RS.get_all(ctx.rs, SomeSyncable) == [%Syncable{body: record, ref_id: {SomeSyncable, -1, 123}}]
  end

  test "Commits a list of new records.", ctx do
    records = Enum.map(0..10, fn(id) -> %SomeSyncable{foo: "hello", bar: "world", id: id} end)
    :ok = RS.commit_records(records, ctx.rs)
    assert Enum.all?(0..10, fn(id) ->
      assert RS.get_by_id(ctx.rs, SomeSyncable, id) == %Syncable{body: %SomeSyncable{foo: "hello", bar: "world", id: id}, ref_id: {SomeSyncable, -1, id}}
    end)
  end

  test "updates a record", ctx do
    record_a = %SomeSyncable{foo: 1, bar: 1, id: 123}
    :ok = RS.commit_records(record_a, ctx.rs)

    record_b = %{record_a | foo: 123, bar: 123}
    RS.commit_records(record_b, ctx.rs)
    r = RS.get_by_id(ctx.rs, SomeSyncable, 123)
    assert r == %Syncable{body: %SomeSyncable{bar: 123, foo: 123, id: 123}, ref_id: {SomeSyncable, -1, 123}}

    refute Enum.count(RS.get_all(ctx.rs, SomeSyncable)) > 2
  end

  test "Inspects the state reasonably.", ctx do
    record = %SomeSyncable{foo: 1, bar: 1, id: 123}
    :ok = RS.commit_records(record, ctx.rs)
    assert inspect( :sys.get_state(ctx.rs)) == "#DatabaseState<[{Farmbot.Database.RecordStorageTest.SomeSyncable, -1, 123}]>"
  end

  test "flushes all records.", ctx do
    record = %SomeSyncable{foo: 1, bar: 1, id: 123}
    :ok = RS.commit_records(record, ctx.rs)
    RS.flush(ctx.rs)
    assert RS.get_all(ctx.rs, SomeSyncable) == []

    assert inspect( :sys.get_state(ctx.rs)) == "#DatabaseState<[]>"
  end

  test "flushes records of one syncable.", ctx do
    record1 = %SomeSyncable{foo: 1, bar: 2, id: 22}
    record2 = %SomeOtherSyncable{foo: 12, baz: 33, id: 123 }
    :ok = RS.commit_records([record1, record2], ctx.rs)
    RS.flush(ctx.rs, SomeSyncable)
    assert RS.get_all(ctx.rs, SomeSyncable) == []
    assert match?([_syncable], RS.get_all(ctx.rs, SomeOtherSyncable))
  end

end
