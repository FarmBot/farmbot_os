defmodule Farmbot.SyncTest do
  use ExUnit.Case, async: true
  setup_all do
    device_id = 123
    fake_sync = Sync.create!(
    %{
      "compat_num" =>0,
      "device" => %{
        "id" => device_id,
        "planting_area_id" => nil,
        "name" => "im just making stuff up",
        "webcam_url" => nil
        },
      "peripherals" =>   [
        %{
          "id" => 34,
          "device_id" => device_id,
          "pin" => 13,
          "mode" => 0,
          "label" => "laser beam",
          "created_at" => "2016-11-28T21:00:55.853Z",
          "updated_at" => "2016-11-28T21:00:55.853Z"
        }
        ],
      "plants" => [],
      "regimen_items" => [
        %{
          "id" => 103,
          "time_offset" => 300000,
          "regimen_id" => 500,
          "sequence_id" => 14
        }
        ],
      "regimens" => [
        %{
          "id" => 500,
          "color" => "gray",
          "name" => "not fake!",
          "device_id" => device_id
        }
        ],
      "sequences" => [
        %{
          "id" => 14,
          "device_id" => device_id,
          "name" => "hello_sequence",
          "color" => "gray",
          "kind" => "sequence",
          "args" => %{},
          "body" => []
        }
        ],
      "users" => [
        %{
          "id" => 9000,
          "device_id" => device_id,
          "name" => "pablo",
          "email" => "hannah_montana@disney.channel",
          "created_at" => "2016-11-28T21:00:55.853Z",
          "updated_at" => "2016-11-28T21:00:55.853Z"
        }
        ],
      "tool_bays" => []
      }
    )

    Farmbot.Sync.put_stuff(fake_sync)
    receive do
      {:sync_complete, _resources} ->
        :ok
      after
        5_000 -> :fail
    end
  end

  test "gets the list of users" do
    users = Farmbot.Sync.get_users
    assert(is_list(users) == true)
    assert(is_syncable(Enum.random(users)) == :__struct__)
  end

  def is_syncable(maybe_syncable) when is_map(maybe_syncable) do
    Map.get(maybe_syncable, :not_struct, :__struct__)
  end

  def is_syncable(_), do: :not_map
end
