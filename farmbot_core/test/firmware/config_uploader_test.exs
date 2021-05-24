defmodule FarmbotCore.Firmware.ConfigUploaderTest do
  use ExUnit.Case
  alias FarmbotCore.Firmware.ConfigUploader

  test "refresh/2 - Empty changes" do
    fake_state = %{tx_buffer: %{}}
    assert fake_state == ConfigUploader.refresh(fake_state, [])
  end
end
