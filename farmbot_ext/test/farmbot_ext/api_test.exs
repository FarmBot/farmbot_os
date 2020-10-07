defmodule FarmbotExt.APITest do
  use ExUnit.Case, async: false
  use Mimic

  setup :verify_on_exit!

  alias FarmbotExt.{
    API,
    APIFetcher
  }

  defmodule FakeResource do
    defstruct [:foo]

    def changeset(_, _) do
    end
  end

  test "unwrap - error" do
    e = {:error, "Testing"}
    assert e == API.unwrap(e, %FakeResource{})
  end

  test "unwrap - many" do
    fake_json = [
      %{x: 50.0, y: 500.0, z: -200.0},
      %{x: -50.0, y: -500.0, z: 200.0}
    ]

    {:ok, results} = API.unwrap({:ok, fake_json}, %FarmbotCore.Asset.Point{})
    [one, two] = results
    assert one.valid?
    assert two.valid?
    assert one.changes == Enum.at(fake_json, 0)
    assert two.changes == Enum.at(fake_json, 1)
  end

  test "unwrap - one" do
    fake_json = %{x: -50.0, y: -500.0, z: 200.0}

    {:ok, one} = API.unwrap({:ok, fake_json}, %FarmbotCore.Asset.Point{})

    assert one.valid?
    assert one.changes == fake_json
  end

  test "get_changeset" do
    fake_changes = %{name: "Test Case"}

    expect(APIFetcher, :get_body!, 1, fn path ->
      assert path == "/api/device/15.json"
      {:ok, fake_changes}
    end)

    device = %FarmbotCore.Asset.Device{id: 15}
    id = device.id

    {:ok, changeset} = API.get_changeset(device, id)
    assert changeset.valid?
    assert changeset.changes == fake_changes
  end
end
