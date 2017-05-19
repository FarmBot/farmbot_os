defmodule Database.Syncable.Fake do
  use Farmbot.Database.Syncable,
      model:    [:foo, :bar],
      endpoint: {"/fake", "/fakes"}
end

defmodule Farmbot.SyncableTest do
  alias Database.Syncable.Fake
  alias Farmbot.Test.Helpers
  require IEx
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Farmbot.Context

  doctest Farmbot.Database.Syncable

  setup_all do
    context = Context.new()
    [my_fake: %Fake{},
     token:   Helpers.login(context.auth)]
  end

  test "defines a syncable", context do
    assert(is_map(context.my_fake))
    assert(context.my_fake.__struct__ == Fake)
  end

  test "singular URLs" do
    assert(Fake.singular_url == "/fake")
  end

  test "plural URLs" do
    assert(Fake.plural_url == "/fakes")
  end

  def get_all_by_id_callback(result) do
    result
  end

  test "fetch all of a resource", _context do
    use_cassette "fake/get_fakes" do
      results = Fake.fetch({__MODULE__, :get_all_by_id_callback, []})
      item = List.first(results)
      assert item.__struct__ == Fake
      assert is_integer(item.id)
    end
  end

  test "fetch a particular id of a resource" do
    use_cassette "fake/get_fake" do
      item = Fake.fetch(2, {__MODULE__, :get_all_by_id_callback, []})
      assert item.__struct__ == Fake
      assert is_integer(item.id)
    end
  end

end
