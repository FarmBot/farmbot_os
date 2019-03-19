defmodule FarmbotCore.BotStateNGTest do
  use ExUnit.Case, async: true

  alias FarmbotCore.BotStateNG

  describe "pins" do
    test "adds pins to the state" do
      orig = BotStateNG.new()
      assert Enum.empty?(orig.pins)

      one_pin =
        BotStateNG.add_or_update_pin(orig, 10, 1, 2)
        |> Ecto.Changeset.apply_changes()

      assert one_pin.pins[10] == %{mode: 1, value: 2}

      two_pins =
        BotStateNG.add_or_update_pin(one_pin, 20, 1, 20)
        |> Ecto.Changeset.apply_changes()

      assert two_pins.pins[10] == %{mode: 1, value: 2}
      assert two_pins.pins[20] == %{mode: 1, value: 20}
    end

    test "updates an existing pin" do
      orig = BotStateNG.new()
      assert Enum.empty?(orig.pins)

      one_pin =
        BotStateNG.add_or_update_pin(orig, 10, 1, 2)
        |> Ecto.Changeset.apply_changes()

      assert one_pin.pins[10] == %{mode: 1, value: 2}

      one_pin_updated =
        BotStateNG.add_or_update_pin(one_pin, 10, 1, 50)
        |> Ecto.Changeset.apply_changes()

      assert one_pin_updated.pins[10] == %{mode: 1, value: 50}
    end
  end

  describe "informational_settings" do
    test "sets update_available" do
      orig = BotStateNG.new()

      assert orig.informational_settings.update_available == false

      mut1 =
        BotStateNG.changeset(orig, %{informational_settings: %{update_available: true}})
        |> Ecto.Changeset.apply_changes()

      assert mut1.informational_settings.update_available == true

      mut2 =
        BotStateNG.changeset(orig, %{informational_settings: %{update_available: false}})
        |> Ecto.Changeset.apply_changes()

      assert mut2.informational_settings.update_available == false
    end

    test "reports soc_temp" do
      orig = BotStateNG.new()

      mut =
        BotStateNG.changeset(orig, %{informational_settings: %{soc_temp: 100}})
        |> Ecto.Changeset.apply_changes()

      assert mut.informational_settings.soc_temp == 100
    end

    test "reports disk_usage" do
      orig = BotStateNG.new()

      mut =
        BotStateNG.changeset(orig, %{informational_settings: %{disk_usage: 100}})
        |> Ecto.Changeset.apply_changes()

      assert mut.informational_settings.disk_usage == 100
    end

    test "reports memory_usage" do
      orig = BotStateNG.new()

      mut =
        BotStateNG.changeset(orig, %{informational_settings: %{memory_usage: 512}})
        |> Ecto.Changeset.apply_changes()

      assert mut.informational_settings.memory_usage == 512
    end

    test "reports uptime" do
      orig = BotStateNG.new()

      mut =
        BotStateNG.changeset(orig, %{informational_settings: %{uptime: 5000}})
        |> Ecto.Changeset.apply_changes()

      assert mut.informational_settings.uptime == 5000
    end

    test "reports wifi_level" do
      orig = BotStateNG.new()

      mut =
        BotStateNG.changeset(orig, %{informational_settings: %{wifi_level: 52}})
        |> Ecto.Changeset.apply_changes()

      assert mut.informational_settings.wifi_level == 52
    end
  end

  describe "enigmas" do
    alias FarmbotCore.Asset.Private.Enigma

    test "registers an engima" do
      state = BotStateNG.new()
      assert Enum.empty?(state.enigmas)
      uuid = Ecto.UUID.generate()

      enigma = %Enigma{
        local_id: uuid,
        priority: 15,
        created_at: DateTime.utc_now()
      }

      state =
        BotStateNG.add_enigma(state, enigma)
        |> Ecto.Changeset.apply_changes()

      refute Enum.empty?(state.enigmas)
      assert state.enigmas[uuid].priority == 15

      # Make sure that the enigma is in the frontend expected schema
      assert state.enigmas[uuid].uuid == uuid

      updated_enigma = %Enigma{enigma | priority: 10}

      state =
        BotStateNG.add_enigma(state, updated_enigma)
        |> Ecto.Changeset.apply_changes()

      assert state.enigmas[uuid].priority == 10

      state =
        BotStateNG.clear_enigma(state, enigma)
        |> Ecto.Changeset.apply_changes()

      refute state.enigmas[uuid]
    end
  end
end
