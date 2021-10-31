defmodule FarmbotOS.Firmware.ConfigUploaderTest do
  use ExUnit.Case
  use Mimic

  require Helpers

  alias FarmbotOS.Firmware.{
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
    expected = %FarmbotOS.Firmware.TxBuffer{
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

    Helpers.expect_log(
      "Updating firmware parameters: [:movement_stop_at_home_z]"
    )

    expect(FarmbotOS.Asset, :firmware_config, 1, fn ->
      %{movement_stop_at_home_z: 1.23}
    end)

    result = ConfigUploader.refresh(@state, @new_keys)
    assert result.tx_buffer == expected
  end
end
