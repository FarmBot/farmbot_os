defmodule FarmbotOS.FbosConfigTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.Asset.FbosConfig, as: Config
  alias FarmbotOS.AssetWorker.FarmbotOS.Asset.FbosConfig, as: Worker

  import ExUnit.CaptureLog
  require Helpers

  @conf %Config{}

  test "init" do
    assert {:ok, %{fbos_config: @conf}} == Worker.init(@conf)
  end

  test "handle unknown message" do
    log =
      capture_log(fn ->
        result = Worker.handle_info(:unknown, %{fbos_config: @conf})
        assert {:noreply, %{fbos_config: @conf}} == result
      end)

    assert log =~ "[debug] !!!UNKNOWN FBOS Config Worker Message: :unknown"
  end

  test "sets boot_sequence_id" do
    Helpers.expect_log("Set boot sequence to My Sequence")

    expect(FarmbotOS.Celery.SysCallGlue, :get_sequence, 1, fn _id ->
      %{meta: %{sequence_name: "My Sequence"}}
    end)

    update = %Config{
      boot_sequence_id: 1
    }

    result =
      Worker.handle_cast(
        {:new_data, update},
        %{fbos_config: @conf}
      )

    assert {:noreply, %{fbos_config: update}} == result
  end

  test "unsets boot_sequence_id" do
    Helpers.expect_log("Set boot sequence to None")

    update = %Config{
      boot_sequence_id: nil
    }

    result =
      Worker.handle_cast(
        {:new_data, update},
        %{
          fbos_config: %Config{
            boot_sequence_id: 1
          }
        }
      )

    assert {:noreply, %{fbos_config: update}} == result
  end

  test "sets os_auto_update" do
    Helpers.expect_log("Set OS auto update to true")

    update = %Config{
      os_auto_update: true
    }

    result =
      Worker.handle_cast(
        {:new_data, update},
        %{fbos_config: @conf}
      )

    assert {:noreply, %{fbos_config: update}} == result
  end

  test "sets network_not_found_timer" do
    Helpers.expect_log("Set connection attempt period to 1 minutes")

    update = %Config{
      network_not_found_timer: 1
    }

    result =
      Worker.handle_cast(
        {:new_data, update},
        %{fbos_config: @conf}
      )

    assert {:noreply, %{fbos_config: update}} == result
  end

  test "sets sequence_body_log" do
    Helpers.expect_log("Set sequence step log messages to true")

    update = %Config{
      sequence_body_log: true
    }

    result =
      Worker.handle_cast(
        {:new_data, update},
        %{fbos_config: @conf}
      )

    assert {:noreply, %{fbos_config: update}} == result
  end

  test "sets sequence_complete_log" do
    Helpers.expect_log("Set sequence complete log messages to true")

    update = %Config{
      sequence_complete_log: true
    }

    result =
      Worker.handle_cast(
        {:new_data, update},
        %{fbos_config: @conf}
      )

    assert {:noreply, %{fbos_config: update}} == result
  end

  test "sets sequence_init_log" do
    Helpers.expect_log("Set sequence init log messages to true")

    update = %Config{
      sequence_init_log: true
    }

    result =
      Worker.handle_cast(
        {:new_data, update},
        %{fbos_config: @conf}
      )

    assert {:noreply, %{fbos_config: update}} == result
  end
end
