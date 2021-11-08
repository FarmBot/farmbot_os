defmodule FarmbotOS.SysCallsTest do
  use ExUnit.Case
  alias FarmbotOS.SysCalls
  alias FarmbotOS.Asset
  alias FarmbotOS.Firmware.Command

  alias FarmbotOS.Asset.{
    Repo,
    Sequence,
    BoxLed
  }

  use Mimic
  setup :verify_on_exit!

  test "emergency_unlock" do
    expect(FarmbotOS.Leds, :yellow, 1, fn mode ->
      assert mode == :off
      :ok
    end)

    expect(FarmbotOS.Leds, :red, 1, fn mode ->
      assert mode == :solid
      :ok
    end)

    expect(Command, :unlock, 1, fn -> :test end)
    assert :ok == SysCalls.emergency_unlock()
  end

  test "emergency_lock" do
    expect(FarmbotOS.Leds, :red, 1, fn mode ->
      assert mode == :off
      :ok
    end)

    expect(FarmbotOS.Leds, :yellow, 1, fn mode ->
      assert mode == :slow_blink
      :ok
    end)

    expect(Command, :lock, 1, fn -> :test end)
    assert :ok == SysCalls.emergency_lock()
  end

  test "wait()" do
    now = :os.system_time(:millisecond)
    SysCalls.wait(100)
    later = :os.system_time(:millisecond)
    assert later >= now + 100
  end

  test "named_pin()" do
    result1 = SysCalls.named_pin("x", 1)
    assert result1 == {:error, "unknown pin kind: x of id: 1"}

    result2 = SysCalls.named_pin("BoxLed23", 45)
    assert %BoxLed{id: 23} == result2

    expect(Asset, :get_sensor, fn id ->
      if id == 67 do
        %{id: id, is_mock: :yep}
      else
        nil
      end
    end)

    result3 = SysCalls.named_pin("Sensor", 67)
    assert %{id: 67, is_mock: :yep} == result3

    result4 = SysCalls.named_pin("Sensor", 89)
    assert {:error, "Could not find peripheral by id: 89"} == result4

    expect(Asset, :get_peripheral, fn [id: id] ->
      if id == 10 do
        %{id: id, is_mock: :yep}
      else
        nil
      end
    end)

    result5 = SysCalls.named_pin("Peripheral", 10)
    assert %{id: 10, is_mock: :yep} == result5

    result6 = SysCalls.named_pin("Peripheral", 11)
    assert {:error, "Could not find peripheral by id: 11"} == result6
  end

  test "get_sequence(id)" do
    _ = Repo.delete_all(Sequence)
    fake_id = 28
    fake_name = "X"

    fake_params = %{
      id: fake_id,
      name: fake_name,
      args: %{
        sequence_name: fake_name
      },
      kind: "sequence",
      body: []
    }

    assert SysCalls.get_sequence(fake_id) == {:error, "sequence not found"}

    %Sequence{id: id} =
      %Sequence{}
      |> Sequence.changeset(fake_params)
      |> Repo.insert!()

    assert id == fake_id
    result = SysCalls.get_sequence(fake_id)
    assert result.args == fake_params[:args]
    assert result.kind == :sequence
    assert result.body == fake_params[:body]
  end

  test "coordinate()" do
    expected = %{x: 1, y: 2, z: 3}
    actual = SysCalls.coordinate(1, 2, 3)
    assert expected == actual
  end

  test "nothing" do
    assert SysCalls.nothing() == nil
  end

  test "fbos_config()" do
    {:ok, conf} = SysCalls.fbos_config()

    expected = FarmbotOS.Asset.FbosConfig.render(FarmbotOS.Asset.fbos_config())

    assert conf == expected
  end
end
