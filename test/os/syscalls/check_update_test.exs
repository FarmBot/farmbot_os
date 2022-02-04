defmodule FarmbotOS.SysCalls.CheckUpdateTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!

  alias FarmbotOS.{
    SysCalls.CheckUpdate,
    UpdateSupport
  }

  test "terminate" do
    expect(FarmbotOS.LogExecutor, :execute, 1, fn log ->
      assert log.message == "Upgrade halted: \"an error\""
    end)

    {:ok, pid} = FarmbotOS.UpdateProgress.start_link([])
    CheckUpdate.terminate("an error", pid)
  end

  test "url_or_nil() - non-nil return" do
    expect(UpdateSupport, :get_target, 1, fn ->
      "rpi9"
    end)

    expect(UpdateSupport, :download_meta_data, 1, fn target ->
      assert target == "rpi9"
      %{"image_url" => "http://localhost:3000/release.fw"}
    end)

    assert CheckUpdate.url_or_nil() == "http://localhost:3000/release.fw"
  end

  test "url_or_nil() - nil return" do
    expect(UpdateSupport, :get_target, 1, fn ->
      "rpi9"
    end)

    expect(UpdateSupport, :download_meta_data, 1, fn target ->
      assert target == "rpi9"
      %{}
    end)

    assert CheckUpdate.url_or_nil() == nil
  end

  test "check_update - OK" do
    expect(UpdateSupport, :in_progress?, 1, fn ->
      false
    end)

    expect(UpdateSupport, :install_update, 1, fn _url_or_nil ->
      :ok
    end)

    expect(FarmbotOS.Celery.SysCallGlue, :reboot, 1, fn ->
      :ok
    end)

    CheckUpdate.check_update()
  end

  test "check_update - NO (in progress)" do
    expect(UpdateSupport, :in_progress?, 1, fn ->
      true
    end)

    expected = {:error, "Installation already started. Please wait or reboot."}
    assert expected == CheckUpdate.check_update()
  end

  test "check_update - NO (misc. error)" do
    expect(UpdateSupport, :get_target, 1, fn ->
      "rpi9"
    end)

    expect(UpdateSupport, :download_meta_data, 1, fn target ->
      assert target == "rpi9"
      %{"image_url" => "http://localhost:3000/release.fw"}
    end)

    expect(UpdateSupport, :in_progress?, 1, fn ->
      false
    end)

    expect(UpdateSupport, :install_update, 1, fn _url_or_nil ->
      {:error, "a unit test"}
    end)

    expect(FarmbotOS.LogExecutor, :execute, 1, fn log ->
      assert log.message == "Upgrade halted: \"a unit test\""
    end)

    CheckUpdate.check_update()
  end

  test "hotfix for OTA issue - timezone / OTA hour set" do
    expect(FarmbotOS.UpdateSupport, :get_hotfix_info, 1, fn ->
      {"America/Chicago", 15}
    end)
    expect(FarmbotOS.UpdateSupport, :do_hotfix, 1, fn -> :ok end)
    expect(Timex, :now, 1, fn _tz -> %{hour: 15} end)
    uptime_seconds = 864_000_000
    CheckUpdate.uptime_hotfix(uptime_seconds)
  end

  test "hotfix for OTA issue - no timezone / OTA hour" do
    expect(FarmbotOS.UpdateSupport, :get_hotfix_info, 1, fn ->
      [
        {"America/Chicago", 15},
        {"America/Chicago", nil},
        {nil, 15},
        {nil, nil}
      ] |> Enum.random()
    end)
    expect(FarmbotOS.UpdateSupport, :do_hotfix, 1, fn -> :ok end)
    uptime_seconds = 864_000_000
    CheckUpdate.uptime_hotfix(uptime_seconds)
  end
end
