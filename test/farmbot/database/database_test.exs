defmodule Farmbot.DatabaseTest do
  alias Farmbot.TestHelpers
  import TestHelpers, only: [read_json: 1]
  use ExUnit.Case, async: false
  alias Farmbot.Database, as: DB
  alias DB.Syncable.Point
  require IEx

  setup_all do
    []
  end

  test "adds a record to the local db" do
    # modulename = Enum.random(DB.all_the_syncables())
    modulename = Point
    plural = modulename.plural_url()
    points_json = read_json("#{plural}.json")

    old = DB.get_all(modulename)

    tagged = Enum.map(points_json, fn(item) ->
      thing = tag_item(item, modulename)
      assert(thing.__struct__ == modulename)
      assert(is_number(thing.id))
      thing
    end)

    :ok = DB.commit_records(tagged, modulename)

    new = DB.get_all(modulename)
    assert Enum.count(new) > Enum.count(old)
  end

  test "wont commit errornous things to db" do
    item = "random_not_json: {}, this isnt formatted_properly!"
    mod = Enum.random(DB.all_the_syncables())
    error = Poison.decode(item)
    old = DB.get_all(mod)

    DB.commit_records(error, mod)

    new = DB.get_all(mod)
    assert Enum.count(new) == Enum.count(old)
  end

  test "gets an item out of the database" do
    modulename = Point
    plural = modulename.plural_url()
    points_json = read_json("#{plural}.json")
    random_item = Enum.random(points_json) |> tag_item(modulename)

    id = random_item.id

    :ok = DB.commit_records(random_item, modulename)
    item = DB.get_by_id(modulename, id)
    assert !is_nil(item)
    assert item.body == random_item
  end

  test "updates an old item" do
    modulename = Point
    plural = modulename.plural_url()
    points_json = read_json("#{plural}.json")
    random_item = Enum.random(points_json) |> tag_item(modulename)

    id = random_item.id

    :ok = DB.commit_records(random_item, modulename)
    updated = %{random_item | name: "hurdur"}

    :ok = DB.commit_records(updated, modulename)

    item = DB.get_by_id(modulename, id)

    assert item.body == updated
  end

  defp tag_item(map, tag) do
    updated_map =
      map
      |> Enum.map(fn({key, val}) ->  {String.to_atom(key), val} end)
      |> Map.new()
    struct(tag, updated_map)
  end
end
