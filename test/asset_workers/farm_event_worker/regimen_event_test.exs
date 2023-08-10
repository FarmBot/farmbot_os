defmodule FarmbotOS.FarmEventWorker.RegimenEventTest do
  use ExUnit.Case
  alias FarmbotOS.FarmEventWorker.RegimenEvent
  alias Farmbot.TestSupport.AssetFixtures
  alias FarmbotOS.Asset
  import ExUnit.CaptureLog
  require Logger
  use Mimic

  @two_days_in_seconds 60 * 60 * 24 * 2

  describe "regimen event scheduler" do
    test "ensures regimen instance exists" do
      regimen = AssetFixtures.regimen(%{})
      farm_event = AssetFixtures.regimen_event(regimen, %{})
      args = %{}

      RegimenEvent.init([farm_event, args])

      state = %{event: farm_event}

      log =
        capture_log(fn ->
          result =
            RegimenEvent.handle_info({:checkup, DateTime.utc_now()}, state)

          assert {:noreply, state} == result
        end)

      assert log =~ "[debug] Ensuring RegimenInstance exists for event"
      # assert_receive :ensure_started
    end

    test "handles not started yet" do
      regimen = AssetFixtures.regimen(%{})
      farm_event = AssetFixtures.regimen_event(regimen, %{})
      args = %{}

      RegimenEvent.init([farm_event, args])

      state = %{event: farm_event, args: %{}}

      log =
        capture_log(fn ->
          result =
            RegimenEvent.handle_info(
              {:checkup,
               DateTime.utc_now()
               |> DateTime.add(-@two_days_in_seconds, :second)},
              state
            )

          assert {:noreply, state} == result
        end)

      assert log =~ ""
      # assert_receive :ensure_not_started
    end

    test "handles regimen instance exists" do
      FarmbotOS.Asset.update_device!(%{timezone: "America/Chicago"})
      regimen = AssetFixtures.regimen(%{})
      farm_event = AssetFixtures.regimen_event(regimen, %{})
      args = %{}

      RegimenEvent.init([farm_event, args])

      state = %{event: farm_event}

      regimen_instance =
        AssetFixtures.regimen_instance(%{}, %{}, %{
          started_at:
            DateTime.utc_now() |> DateTime.add(-@two_days_in_seconds, :second)
        })

      stub(FarmbotOS.Asset, :get_regimen_instance, fn _fe ->
        regimen_instance
      end)

      log =
        capture_log(fn ->
          result = RegimenEvent.handle_info({:ensure_started}, state)

          assert {:noreply, state} == result
        end)

      assert log =~ ""
      # assert_receive :ensure_unchanged
    end

    test "creates regimen instance" do
      FarmbotOS.Asset.update_device!(%{timezone: "America/Chicago"})
      regimen = AssetFixtures.regimen(%{})
      farm_event = AssetFixtures.regimen_event(regimen, %{})
      args = %{}

      RegimenEvent.init([farm_event, args])

      state = %{event: farm_event}

      log =
        capture_log(fn ->
          result = RegimenEvent.handle_info({:ensure_started}, state)

          assert {:noreply, state, :hibernate} == result
        end)

      assert log =~ "[debug] Creating RegimenInstance for event"
    end

    test "removes regimen instance" do
      FarmbotOS.Asset.update_device!(%{timezone: "America/Chicago"})
      regimen = AssetFixtures.regimen(%{})
      farm_event = AssetFixtures.regimen_event(regimen, %{id: 123})
      args = %{}

      RegimenEvent.init([farm_event, args])

      state = %{event: farm_event, args: %{}}

      regimen_instance =
        AssetFixtures.regimen_instance(%{}, %{}, %{
          started_at:
            DateTime.utc_now() |> DateTime.add(@two_days_in_seconds, :second)
        })

      stub(FarmbotOS.Asset, :get_regimen_instance, fn _fe ->
        regimen_instance
      end)

      log =
        capture_log(fn ->
          result = RegimenEvent.handle_info({:ensure_not_started}, state)

          assert {:noreply, state, :hibernate} == result
        end)

      assert log =~ "[debug] RegimenInstance shouldn't exist for event"
    end

    test "changes regimen instance" do
      Asset.update_device!(%{timezone: "America/Chicago"})
      regimen = AssetFixtures.regimen(%{})
      farm_event = AssetFixtures.regimen_event(regimen, %{})
      args = %{}

      RegimenEvent.init([farm_event, args])

      state = %{event: farm_event}

      regimen_instance =
        AssetFixtures.regimen_instance(%{}, %{}, %{
          started_at:
            DateTime.utc_now()
            |> DateTime.add(@two_days_in_seconds * 2, :second)
        })

      stub(FarmbotOS.Asset, :get_regimen_instance, fn _fe ->
        regimen_instance
      end)

      log =
        capture_log(fn ->
          result = RegimenEvent.handle_info({:ensure_unchanged}, state)

          assert {:noreply, state, :hibernate} == result
        end)

      assert log =~ "[debug] RegimenInstance start time changed for event"
    end
  end
end
