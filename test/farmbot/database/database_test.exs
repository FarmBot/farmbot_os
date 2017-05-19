defmodule Farmbot.DatabaseTest do
  alias Farmbot.Test.Helpers
  import Helpers, only: [read_json: 1, tag_item: 2]

  use ExUnit.Case, async: false
  alias Farmbot.Database, as: DB
  alias Farmbot.Context
  alias DB.Syncable.Point
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  require IEx

  setup_all do
    ctx = Context.new()
    {:ok, db} = DB.start_link(ctx, [])
    context = %{ctx | database: db}
    [token: Helpers.login(context.auth), cs_context: context]
  end

  test "sync" do
    ctx = Context.new()
    {:ok, db} = DB.start_link(ctx, [])
    context = %{ctx | database: db}
    :ok = DB.flush(context)

    use_cassette "sync/corner_case" do
      before_state = :sys.get_state(db)
      before_count = Enum.count(before_state.all)

      DB.sync(context)

      after_state  = :sys.get_state(db)
      after_count  = Enum.count(after_state.all)
      assert(before_count < after_count)
    end
  end


  test "adds a record to the local db", %{cs_context: ctx} do
    # modulename = Enum.random(DB.all_syncable_modules())
    modulename = Point
    plural = modulename.plural_url()
    points_json = read_json("#{plural}.json")

    old = DB.get_all(ctx, modulename)

    tagged = Enum.map(points_json, fn(item) ->
      thing = tag_item(item, modulename)
      assert(thing.__struct__ == modulename)
      assert(is_number(thing.id))
      thing
    end)

    :ok = DB.commit_records(tagged, ctx, modulename)

    new = DB.get_all(ctx, modulename)
    assert Enum.count(new) > Enum.count(old)
  end

  test "wont commit errornous things to db", %{cs_context: ctx} do
    item   = "random_not_json: {}, this isnt formatted_properly!"
    mod    = Enum.random(DB.all_syncable_modules())
    error  = Poison.decode(item)
    old    = DB.get_all(ctx, mod)

    DB.commit_records(error, ctx, mod)

    new = DB.get_all(ctx, mod)
    assert Enum.count(new) == Enum.count(old)
  end

  test "gets an item out of the database", %{cs_context: ctx} do
    modulename  = Point
    plural      = modulename.plural_url()
    points_json = read_json("#{plural}.json")
    random_item = Enum.random(points_json) |> tag_item(modulename)

    id = random_item.id

    :ok = DB.commit_records(random_item, ctx, modulename)
    item = DB.get_by_id(ctx, modulename, id)
    assert !is_nil(item)
    assert item.body == random_item
  end

  test "updates an old item", %{cs_context: ctx} do
    modulename = Point
    plural = modulename.plural_url()
    points_json = read_json("#{plural}.json")
    random_item = Enum.random(points_json) |> tag_item(modulename)

    id = random_item.id

    :ok = DB.commit_records(random_item, ctx, modulename)
    updated = %{random_item | name: "hurdur"}

    :ok = DB.commit_records(updated, ctx, modulename)

    item = DB.get_by_id(ctx, modulename, id)

    assert item.body == updated
  end

  test "toggles awaiting state for resources", %{cs_context: ctx} do
    DB.set_awaiting(ctx, Point, 0, 0)
    assert(DB.get_awaiting(ctx, Point))

    DB.unset_awaiting(ctx, Point)
    refute(DB.get_awaiting(ctx, Point))

    DB.set_awaiting(ctx, Point, 0, 0)
    assert(DB.get_awaiting(ctx, Point))

    DB.unset_awaiting(ctx, Point)
    refute(DB.get_awaiting(ctx, Point))
  end

end
