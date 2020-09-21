defmodule FarmbotOS.UpdateSupportTest do
  use ExUnit.Case, async: true
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.UpdateSupport

  test "handle_http_response - 422 error" do
    body = %{1 => "A", 2 => "B"}
    {:ok, json} = FarmbotCore.JSON.encode(body)
    fake_payload = {:ok, {{"", 422, ""}, [], json}}
    expected = %{"image_url" => nil}
    expect(FarmbotCore.LogExecutor, :execute, 1, fn log ->
      assert log.message == "Not updating: [\"A\", \"B\"]"
    end)
    actual = UpdateSupport.handle_http_response(fake_payload)


    assert expected == actual
  end

  test "handle_http_response - 500 error" do
    body = %{1 => "A", 2 => "B"}
    {:ok, json} = FarmbotCore.JSON.encode(body)
    fake_payload = {:ok, {{"", 500, ""}, [], json}}
    expected = %{"image_url" => nil}
    expect(FarmbotCore.LogExecutor, :execute, 1, fn log ->
      msg = "Error downloading update. Please try again. "<>
      "{:ok, {{\"\", 500, \"\"}, [], "<>
      "\"{\\\"1\\\":\\\"A\\\",\\\"2\\\":\\\"B\\\"}\"}}"

      assert log.message == msg
    end)

    actual = UpdateSupport.handle_http_response(fake_payload)


    assert expected == actual
  end

  test "handle_http_response - 200 OK" do
    body = %{"foo" => "bar"}
    {:ok, json} = FarmbotCore.JSON.encode(body)
    fake_payload = {:ok, {{"", 200, ""}, [], json}}

    assert body == UpdateSupport.handle_http_response(fake_payload)
  end

  test "do_flash_firmware" do
    expect(System, :cmd, 1, fn path, args ->
      assert path == "fwup"

      assert args == [
               "-a",
               "-i",
               "/root/upgrade.fw",
               "-d",
               "/dev/mmcblk0",
               "-t",
               "upgrade"
             ]

      {:ok, 0}
    end)

    UpdateSupport.do_flash_firmware()
  end
end
