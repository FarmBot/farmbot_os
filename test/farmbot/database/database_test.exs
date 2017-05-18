defmodule Farmbot.DatabaseTest do
  alias Farmbot.TestHelpers
  import TestHelpers, only: [read_json: 1, tag_item: 2]

  use ExUnit.Case, async: false
  alias Farmbot.Database, as: DB
  alias Farmbot.CeleryScript.Ast.Context
  alias DB.Syncable.Point
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  require IEx

  setup_all do
    {:ok, db} = DB.start_link([])
    context = Context.new()
    [token: TestHelpers.login(context.auth), db: db]
  end

  test "sync" do
    {:ok, db} = DB.start_link([])
    :ok = DB.flush(db)

    use_cassette "sync/corner_case" do
      before_state = :sys.get_state(db)
      before_count = Enum.count(before_state.all)

      DB.sync(db)

      after_state  = :sys.get_state(db)
      after_count  = Enum.count(after_state.all)
      assert(before_count < after_count)
    end
  end


  test "adds a record to the local db", %{db: db} do
    # modulename = Enum.random(DB.all_syncable_modules())
    modulename = Point
    plural = modulename.plural_url()
    points_json = read_json("#{plural}.json")

    old = DB.get_all(db, modulename)

    tagged = Enum.map(points_json, fn(item) ->
      thing = tag_item(item, modulename)
      assert(thing.__struct__ == modulename)
      assert(is_number(thing.id))
      thing
    end)

    :ok = DB.commit_records(tagged, db, modulename)

    new = DB.get_all(db, modulename)
    assert Enum.count(new) > Enum.count(old)
  end

  test "wont commit errornous things to db", %{db: db} do
    item   = "random_not_json: {}, this isnt formatted_properly!"
    mod    = Enum.random(DB.all_syncable_modules())
    error  = Poison.decode(item)
    old    = DB.get_all(db,mod)

    DB.commit_records(error, db, mod)

    new = DB.get_all(db, mod)
    assert Enum.count(new) == Enum.count(old)
  end

  test "gets an item out of the database", %{db: db} do
    modulename  = Point
    plural      = modulename.plural_url()
    points_json = read_json("#{plural}.json")
    random_item = Enum.random(points_json) |> tag_item(modulename)

    id = random_item.id

    :ok = DB.commit_records(random_item, db, modulename)
    item = DB.get_by_id(db, modulename, id)
    assert !is_nil(item)
    assert item.body == random_item
  end

  test "updates an old item", %{db: db} do
    modulename = Point
    plural = modulename.plural_url()
    points_json = read_json("#{plural}.json")
    random_item = Enum.random(points_json) |> tag_item(modulename)

    id = random_item.id

    :ok = DB.commit_records(random_item, db, modulename)
    updated = %{random_item | name: "hurdur"}

    :ok = DB.commit_records(updated, db, modulename)

    item = DB.get_by_id(db, modulename, id)

    assert item.body == updated
  end

  test "toggles awaiting state for resources", %{db: db} do
    DB.set_awaiting(db, Point, 0, 0)
    assert(DB.get_awaiting(db, Point))

    DB.unset_awaiting(db, Point)
    refute(DB.get_awaiting(db, Point))

    DB.set_awaiting(db, Point, 0, 0)
    assert(DB.get_awaiting(db, Point))

    DB.unset_awaiting(db, Point)
    refute(DB.get_awaiting(db, Point))
  end

end
