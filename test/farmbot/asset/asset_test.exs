defmodule Farmbot.AssetTest do
  use ExUnit.Case, async: false
  alias Farmbot.Asset

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Farmbot.Repo.current_repo())
  end

  test "Returns nil if no sensor" do
    refute Asset.get_sensor_by_id(10000)
  end
end
