defmodule Database.Syncable.Fake do
  use Farmbot.Database.Syncable,
      model:    [:foo, :bar],
      endpoint: {"/fake", "/fakes"}
end

defmodule Farmbot.SyncableTest do
  alias Farmbot.TestHelpers
  alias Database.Syncable.Fake
  import TestHelpers, only: [read_json: 1, tag_item: 2]
  use ExUnit.Case, async: false
  alias Farmbot.Database, as: DB
  alias DB.Syncable.Point
  require IEx

  setup_all do
    [my_fake: %Fake{}]
  end

  test "defines a syncable", context do
    assert(is_map(context.my_fake))
    assert(context.my_fake.__struct__ == Fake)
  end

  test "singular URLs", context do
    assert(context.my_fake.__struct__.singular_url == "/fake")
  end

  test "plural URLs", context do
    assert(context.my_fake.__struct__.plural_url == "/fakes")
  end
end
