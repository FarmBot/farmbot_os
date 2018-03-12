defmodule Farmbot.AssetTest do
  use ExUnit.Case, async: false
  alias Farmbot.Asset
  alias Asset.{Sensor, Peripheral, Sequence, Tool, Point}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Farmbot.Repo.current_repo())
    {:ok, repo: Farmbot.Repo.current_repo()}
  end

  test "Returns nil if no Sensor" do
    refute Asset.get_sensor_by_id(999)
  end

  test "Gets a sensor", %{repo: repo} do
    s = sensor(500, 1, 1, "Rain") |> repo.insert!()
    assert Asset.get_sensor_by_id(s.id) == s
  end

  defp sensor(id, pin, mode, label) do
    %Sensor{id: id, pin: pin, mode: mode, label: label}
  end

  test "Returns nil if no Peripheral" do
    refute Asset.get_peripheral_by_id(9000)
  end

  test "Gets a Peripheral", %{repo: repo} do
    p = peripheral(400, 1, 1, "LEDS") |> repo.insert!()
    assert Asset.get_peripheral_by_id(p.id) == p
  end

  defp peripheral(id, pin, mode, label) do
    %Peripheral{id: id, pin: pin, mode: mode, label: label}
  end

  test "Returns nil if no Sequence" do
    refute Asset.get_sequence_by_id(5000)
  end

  test "Gets a sequence", %{repo: repo} do
    s = sequence(120, "Acuate LEDS", "sequence", %{}, []) |> repo.insert!()
    assert Asset.get_sequence_by_id(s.id) == s
  end

  defp sequence(id, name, kind, args, body) do
    %Sequence{id: id, name: name, kind: kind, args: args, body: body}
  end

  test "Returns nil if no Point" do
    refute Asset.get_point_by_id(9000)
  end

  test "Return snil if no Tool" do
    refute Asset.get_tool_by_id(9000)
  end

  test "Gets a tool", %{repo: repo} do
    t = tool(155, "Trench Digger") |> repo.insert!()
    assert Asset.get_tool_by_id(t.id) == t
  end

  test "Returns nil when there is no point for a tool" do
    refute Asset.get_point_from_tool(123)  
  end

  test "Gets a tool from a point", %{repo: repo} do
    t = tool(120, "Laser beam") |> repo.insert!()
    p = point(111, "Laser holder", t.id, 0, 1, 0, %{}, Tool) |> repo.insert!()
    res = Asset.get_point_from_tool(t.id)
    assert res.id == p.id
    assert res.name == "Laser holder"
  end

  defp tool(id, name) do
    %Tool{id: id, name: name}
  end

  defp point(id, name, tool_id, x, y, z, meta, pointer_type) do
    %Point{id: id, name: name, tool_id: tool_id, x: x, y: y, z: z, meta: meta, pointer_type: pointer_type}
  end
end
