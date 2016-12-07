defmodule Farmbot.Sync.SyncObjectTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "validates and creates a SyncObject" do
    {:ok, blah } = Farmbot.Sync.SyncObject.validate(json_resp)
    assert blah.__struct__ == Farmbot.Sync.SyncObject
  end

  test "validates and does not raise an exception" do
    blah = Farmbot.Sync.SyncObject.validate!({:ok, json_resp})
    assert blah.__struct__ == Farmbot.Sync.SyncObject
  end

  test "does not create a sync object and raises a runtime exception" do
    assert_raise RuntimeError, fn() ->
       Farmbot.Sync.SyncObject.validate!("nope")
    end
  end

  test "does not create a SyncObject" do
    {error, _reason} = Farmbot.Sync.SyncObject.validate(%{})
    assert error == :error
  end

  test "gives meaningful messages when something is wrong" do
    json =
      %{"device" => %{"id" => 1},
        "peripherals" => [],
        "plants" => [],
        "regimen_items" => [],
        "regimens" => [],
        "sequences" => [],
        "tool_bays" => [],
        "tool_slots" => [],
        "tools" => [],
        "users" => []}
    {error, module, reason} = Farmbot.Sync.SyncObject.validate(json)
    assert error == :error
    assert module == Farmbot.Sync.Database.Device
    assert reason == {:missing_keys, ["planting_area_id", "name", "webcam_url"]}
  end

  test "makes sure all keys are validated" do
    json1 = json_resp |> break("device")
    {:error, Farmbot.Sync.Database.Device, reason1} = Farmbot.Sync.SyncObject.validate(json1)
    assert reason1 == :bad_map

    json2 = json_resp |> break("peripherals")
    {:error, Farmbot.Sync.Database.Peripheral, reason2} = Farmbot.Sync.SyncObject.validate(json2)
    assert reason2 == ["failure"]

    json3 = json_resp |> break("plants")
    {:error, Farmbot.Sync.Database.Plant, reason3} = Farmbot.Sync.SyncObject.validate(json3)
    assert reason3 == ["failure"]

    json4 = json_resp |> break("regimen_items")
    {:error, Farmbot.Sync.Database.RegimenItem, reason4} = Farmbot.Sync.SyncObject.validate(json4)
    assert reason4 == ["failure"]

    json5 = json_resp |> break("regimens")
    {:error, Farmbot.Sync.Database.Regimen, reason5} = Farmbot.Sync.SyncObject.validate(json5)
    assert reason5 == ["failure"]

    json6 = json_resp |> break("sequences")
    {:error, Farmbot.Sync.Database.Sequence, reason6} = Farmbot.Sync.SyncObject.validate(json6)
    assert reason6 == ["failure"]

    json7 = json_resp |> break("tool_bays")
    {:error, Farmbot.Sync.Database.ToolBay, reason7} = Farmbot.Sync.SyncObject.validate(json7)
    assert reason7 == ["failure"]

    json8 = json_resp |> break("tool_slots")
    {:error, Farmbot.Sync.Database.ToolSlot, reason8} = Farmbot.Sync.SyncObject.validate(json8)
    assert reason8 == ["failure"]

    json9 = json_resp |> break("tools")
    {:error, Farmbot.Sync.Database.Tool, reason9} = Farmbot.Sync.SyncObject.validate(json9)
    assert reason9 == ["failure"]


    json10 = json_resp |> break("users")
    {:error, Farmbot.Sync.Database.User, reason10} = Farmbot.Sync.SyncObject.validate(json10)
    assert reason10 == ["failure"]

  end

  def break(map, key) do
    Map.put(map, key, ["failure"])
  end

  def json_resp do
    %{"device" => json_device,
      "peripherals" => json_peripherals,
      "plants" => [],
      "regimen_items" => json_regimen_items,
      "regimens" => json_regimens,
      "sequences" => json_sequences,
      "tool_bays" => json_tool_bays,
      "tool_slots" => json_tool_slots,
      "tools" => json_tools,
      "users" => json_users}
  end

  def json_device do
    %{
      "id" => 1,
      "planting_area_id" => 1,
      "name" => Faker.Lorem.word,
      "webcam_url" => Faker.Internet.url
    }
  end

  def json_peripherals,  do: [json_peripheral]
  def json_peripheral do
    %{
      "id" => 1,
      "device_id" => 1,
      "pin" => 13,
      "mode" => 0,
      "label" => Faker.Lorem.Shakespeare.hamlet,
      "created_at" => 12345,
      "updated_at" => 12345
    }
  end

  def json_regimens, do: [json_regimen]
  def json_regimen do
    %{
      "id" => 1,
      "color" => "green",
      "name" => Faker.Company.name,
      "device_id" => 1
    }
  end

  def json_regimen_items, do: [json_regimen_item]
  def json_regimen_item do
    %{
      "id" => 1,
      "time_offset" => 123,
      "regimen_id" => 1,
      "sequence_id" => 1
    }
  end

  def json_sequences, do: [json_sequence]
  def json_sequence do
    %{
      "kind" => "sequence",
      "args" => %{},
      "body" => [],
      "color" => "red",
      "device_id" => 1,
      "id" => 1,
      "name" => Faker.Company.name
    }
  end

  def json_tool_bays, do: [json_tool_bay]
  def json_tool_bay do
    %{
      "id" => 1,
      "device_id" => 1,
      "name" => Faker.Company.name
    }
  end

  def json_tool_slots, do: [json_tool_slot]
  def json_tool_slot do
    %{
      "id" => 1,
      "tool_bay_id" => 1,
      "name" => Faker.Company.name,
      "x" => 1,
      "y" => 2,
      "z" => -1
    }
  end

  def json_tools, do: [json_tool]
  def json_tool do
    %{
      "id" => 1,
      "slot_id" => 1,
      "name" => Faker.Company.name
    }
  end

  def json_users, do: [json_user]
  def json_user do
    %{
      "id" => 1,
      "device_id" => 1,
      "name" => Faker.Company.name,
      "email" => Faker.Internet.email,
      "created_at" => 1234,
      "updated_at" => 1234
    }
  end


end
