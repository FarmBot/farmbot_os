defmodule FarmbotOS.EasterEggsTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.EasterEggs

  test "load_data/0" do
    %{"verbs" => verbs} = EasterEggs.load_data()
    idk = "¯\\_(ツ)_/¯"
    assert Enum.member?(verbs, idk)
  end
end
