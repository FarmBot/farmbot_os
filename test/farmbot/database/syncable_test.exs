defmodule Database.Syncable.Fake do
  use Farmbot.Database.Syncable,
      model:    [:foo, :bar],
      endpoint: {"/fake", "/fakes"}
end

defmodule Farmbot.SyncableTest do
  alias Database.Syncable.Fake
  alias Farmbot.TestHelpers
  import TestHelpers, only: [read_json: 1, tag_item: 2]
  require IEx
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    [my_fake: %Fake{},
     token:   TestHelpers.login()]
  end

  test "defines a syncable", context do
    assert(is_map(context.my_fake))
    assert(context.my_fake.__struct__ == Fake)
  end

  test "singular URLs", context do
    assert(Fake.singular_url == "/fake")
  end

  test "plural URLs", context do
    assert(Fake.plural_url == "/fakes")
  end

  def get_all_by_id_callback(result), do: result

  test "get_all_by_id()", context do
    use_cassette "get_fakes" do
      result = Fake.fetch({__MODULE__, :get_all_by_id_callback, []})
      IEx.pry
    end
  end
end
