defmodule Farmbot.DatabaseTest do
  alias Farmbot.Test.Helpers

  use ExUnit.Case, async: false
  alias Farmbot.Database, as: DB
  alias Farmbot.Context
  alias DB.Syncable.Point
  alias Farmbot.Test.Helpers
  import Helpers, only: [tag_item: 2]

  setup_all do
    ctx = Context.new()
    {:ok, db} = DB.start_link(ctx, [])
    context = %{ctx | database: db}
    [cs_context: Helpers.login(context)]
  end

  # HTTP STUB IS R BROKE
  # test "sync" do
  #   ctx = Context.new()
  #   {:ok, db} = DB.start_link(ctx, [])
  #   context = %{ctx | database: db}
  #   :ok = DB.flush(context)
  #
  #   use_cassette "sync/corner_case" do
  #     before_state = :sys.get_state(db)
  #     before_count = Enum.count(before_state.all)
  #
  #     DB.sync(context)
  #
  #     after_state  = :sys.get_state(db)
  #     after_count  = Enum.count(after_state.all)
  #     assert(before_count < after_count)
  #   end
  # end


  test "adds a record to the local db", %{cs_context: ctx} do
    # modulename = Enum.random(DB.all_syncable_modules())
    modulename = Point
    plural = modulename.plural_url()
    points_json = File.read!("fixture/api_fixture/points.json")
    points = Poison.decode!(points_json) |> Poison.decode!

    old = DB.get_all(ctx, modulename)

    tagged = Enum.map(points, fn(item) ->
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
    points_json = File.read!("fixture/api_fixture/points.json")
    points      = Poison.decode!(points_json) |> Poison.decode!
    random_item = Enum.random(points) |> tag_item(modulename)

    id = random_item.id

    :ok = DB.commit_records(random_item, ctx, modulename)
    item = DB.get_by_id(ctx, modulename, id)
    assert !is_nil(item)
    assert item.body == random_item
  end

  test "updates an old item", %{cs_context: ctx} do
    modulename = Point
    plural = modulename.plural_url()
    points_json = File.read!("fixture/api_fixture/points.json")
    points      = Poison.decode!(points_json) |> Poison.decode!
    random_item = Enum.random(points) |> tag_item(modulename)

    id = random_item.id

    :ok = DB.commit_records(random_item, ctx, modulename)
    updated = %{random_item | name: "hurdur"}

    :ok = DB.commit_records(updated, ctx, modulename)

    item = DB.get_by_id(ctx, modulename, id)

    assert item.body == updated
  end

  test "toggles awaiting state for resources", %{cs_context: ctx} do
    DB.set_awaiting(ctx, Point, :remove, 1)
    assert(DB.get_awaiting(ctx, Point))

    DB.unset_awaiting(ctx, Point)
    refute(DB.get_awaiting(ctx, Point))

    DB.set_awaiting(ctx, Point, :remove, 1)
    assert(DB.get_awaiting(ctx, Point))

    DB.unset_awaiting(ctx, Point)
    refute(DB.get_awaiting(ctx, Point))
  end

  test "removes resources on set awaiting", %{cs_context: ctx} do
    DB.set_awaiting(ctx, Point, :remove, "*")
    assert(DB.get_awaiting(ctx, Point))

    state = :sys.get_state(ctx.database)
    assert state.by_kind[Point] == []

    in_all? = Enum.any?(state.all, fn(ref) ->
      match?({Point, _, _}, ref)
    end)

    refute in_all?

    in_refs? = Enum.any?(state.refs, fn(thing) ->
      match? {{Point, _, _}, _}, thing
    end)

    refute in_refs?

    in_by_kind_and_id? = Enum.any?(Map.keys(state.by_kind_and_id), fn(thing) ->
      match? {Point, _}, thing
    end)

    refute in_by_kind_and_id?
  end

  test "removes a particular item by id", %{cs_context: ctx} do
    json = ~w"""
    {
    "id": 4999,
    "created_at": "2017-05-16T16:26:13.261Z",
    "updated_at": "2017-05-16T16:26:13.261Z",
    "device_id": 2,
    "meta": {},
    "name": "Cabbage 2",
    "pointer_type": "Plant",
    "radius": 50,
    "x": 2,
    "y": 2,
    "z": 2,
    "openfarm_slug": "cabbage"
   }
    """

    modulename = Point
    item = Poison.decode!(json)
    thing = tag_item(item, modulename)
    assert(thing.__struct__ == modulename)
    assert(is_number(thing.id))

    :ok = DB.commit_records([thing], ctx, modulename)

    DB.set_awaiting(ctx, Point, :remove, 4999)
    assert(DB.get_awaiting(ctx, Point))

    state = :sys.get_state(ctx.database)

    in_all? = Enum.find(state.all, fn({syncable, _, id}) ->
       (syncable == Point) && (id == 4999)
    end)
    refute in_all?

    in_refs? = Enum.any?(state.refs, fn({{syncable, _, id}, _}) ->
      (syncable == Point) && (id == 4999)
    end)

    refute in_refs?

    in_by_kind_and_id? = Enum.any?(Map.keys(state.by_kind_and_id), fn({syncable, id}) ->
      (syncable == Point) && (id == 4999)
    end)

    refute in_by_kind_and_id?



  end

end
