defmodule Farmbot.Asset.FarmEventTest do
  alias Farmbot.Repo
  alias Farmbot.Asset.FarmEvent
  use ExUnit.Case, async: true

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo.A)
  end

  @farm_event_seq %{
    "end_time" => "2017-09-20T19:07:00.000000Z",
    "executable_id" => 132,
    "executable_type" => "Sequence",
    "id" => 379,
    "repeat" => 1,
    "start_time" => "2017-09-20T19:06:00.000000Z",
    "time_unit" => "never"
  }

  test "inserts farm_event" do
    assert(
      @farm_event_seq
      |> Poison.encode!()
      |> Poison.decode!(as: %FarmEvent{})
      |> FarmEvent.changeset()
      |> Repo.A.insert()
    )

    import Ecto.Query
    id = @farm_event_seq["id"]
    assert match?([_], from(fe in FarmEvent, where: fe.id == ^id, select: fe) |> Repo.A.all())
  end
end
