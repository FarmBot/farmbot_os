defmodule FarmbotOS.APITest do
  use ExUnit.Case
  use Mimic

  setup :verify_on_exit!

  alias FarmbotOS.{
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

    {:ok, results} = API.unwrap({:ok, fake_json}, %FarmbotOS.Asset.Point{})
    [one, two] = results
    assert one.valid?
    assert two.valid?
    assert one.changes == Enum.at(fake_json, 0)
    assert two.changes == Enum.at(fake_json, 1)
  end

  test "unwrap - one" do
    fake_json = %{x: -50.0, y: -500.0, z: 200.0}

    {:ok, one} = API.unwrap({:ok, fake_json}, %FarmbotOS.Asset.Point{})

    assert one.valid?
    assert one.changes == fake_json
  end

  def stub_the_fetcher(expected_path, fake_changes) do
    expect(APIFetcher, :get_body!, 1, fn path ->
      assert path == expected_path
      {:ok, fake_changes}
    end)
  end

  test "get_changeset" do
    resource = %FarmbotOS.Asset.Device{id: 15}
    id = resource.id
    fake_changes = %{name: "Test Case"}
    expected_path = "/api/device/15.json"
    stub_the_fetcher(expected_path, fake_changes)
    {:ok, changeset} = API.get_changeset(resource, id)
    assert changeset.valid?
    assert changeset.changes == fake_changes
  end

  test "get_changeset(module, path) when is_atom(module)" do
    fake_changes = %{name: "Test Case"}
    expected_path = "/api/device/15.json"
    stub_the_fetcher(expected_path, fake_changes)
    {:ok, changeset} = API.get_changeset(FarmbotOS.Asset.Device, "15")
    assert changeset.valid?
    assert changeset.changes == fake_changes
  end

  test "get_changeset - FirmwareConfig" do
    resource = %FarmbotOS.Asset.FirmwareConfig{id: 15}
    id = resource.id
    fake_changes = %{movement_timeout_y: 4.56}
    expected_path = "/api/firmware_config.json"
    stub_the_fetcher(expected_path, fake_changes)
    {:ok, changeset} = API.get_changeset(resource, id)
    assert changeset.valid?
    assert changeset.changes == fake_changes
  end

  test "get_changeset - FbosConfig" do
    resource = %FarmbotOS.Asset.FbosConfig{id: 15}
    id = resource.id
    fake_changes = %{firmware_path: "/dev/null"}
    expected_path = "/api/fbos_config.json"
    stub_the_fetcher(expected_path, fake_changes)
    {:ok, changeset} = API.get_changeset(resource, id)
    assert changeset.valid?
    assert changeset.changes == fake_changes
  end

  test "get_changeset - FirmwareConfig (Module only)" do
    resource = %FarmbotOS.Asset.FirmwareConfig{id: 15}
    id = resource.id
    fake_changes = %{pin_guard_5_active_state: 2.3}
    expected_path = "/api/firmware_config.json"
    stub_the_fetcher(expected_path, fake_changes)
    {:ok, changeset} = API.get_changeset(FarmbotOS.Asset.FirmwareConfig, id)
    assert changeset.valid?
    assert changeset.changes == fake_changes
  end

  test "get_changeset - FbosConfig (Module only)" do
    resource = %FarmbotOS.Asset.FbosConfig{id: 15}
    id = resource.id
    fake_changes = %{firmware_path: "/dev/null"}
    expected_path = "/api/fbos_config.json"
    stub_the_fetcher(expected_path, fake_changes)
    {:ok, changeset} = API.get_changeset(FarmbotOS.Asset.FbosConfig, id)
    assert changeset.valid?
    assert changeset.changes == fake_changes
  end
end
