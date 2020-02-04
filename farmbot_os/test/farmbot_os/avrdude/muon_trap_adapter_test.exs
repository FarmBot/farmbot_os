defmodule AvrDude.MuonTrapAdapterTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias Avrdude.MuonTrapAdapter

  test "adapter()" do
    assert Avrdude.MuonTrapTestAdapter == MuonTrapAdapter.adapter()
  end
end
