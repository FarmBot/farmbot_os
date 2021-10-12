defmodule FarmbotCore.Firmware.ConfigUploaderTest do
  use ExUnit.Case
  use Mimic

  import ExUnit.CaptureLog

  alias FarmbotCore.Firmware.{
    ConfigUploader,
    UARTCore,
    GCode
  }

  test "refresh/2 - Empty changes" do
    fake_state = %{tx_buffer: %{}}
    assert fake_state == ConfigUploader.refresh(fake_state, [])
  end

  @new_keys [:movement_stop_at_home_z]
  @state %UARTCore{}

  test "refresh/2" do
    expected = %FarmbotCore.Firmware.TxBuffer{
      autoinc: 2,
      current: nil,
      queue: [
        %{
          caller: nil,
          gcode: GCode.new(:F22, P: 47, V: 1.23),
          id: 2
        }
      ]
    }

    t = fn ->
      result = ConfigUploader.refresh(@state, @new_keys)
      assert result.tx_buffer == expected
    end

    expect(FarmbotCore.Asset, :firmware_config, 1, fn ->
      %{movement_stop_at_home_z: 1.23}
    end)

    assert capture_log(t) =~
             "Updating firmware parameters: [:movement_stop_at_home_z]"
  end
end
