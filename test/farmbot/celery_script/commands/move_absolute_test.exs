defmodule Farmbot.CeleryScript.Command.MoveAbsoluteTest do
  alias Farmbot.CeleryScript.{Command, Ast}
  alias Farmbot.Database, as: DB
  alias DB.Syncable.Point
  alias Farmbot.Test.Helpers
  use   Helpers.SerialTemplate, async: false

  describe "move_absolute" do
    test "makes sure we have serial", %{cs_context: context} do
      assert Farmbot.Serial.Handler.available?(context) == true
    end

    test "moves to a location", %{cs_context: context} do
      [_curx, _cury, _curz] = Farmbot.BotState.get_current_pos(context)
      location = %Ast{kind: "coordinate", args: %{x: 1000, y: 0, z: 0}, body: []}
      offset = %Ast{kind: "coordinate", args: %{x: 0, y: 0, z: 0}, body: []}
      Command.move_absolute(%{speed: 8000, offset: offset, location: location}, [], context)
      Process.sleep(100) # wait for serial to catch up
      [newx, _newy, _newz] = Farmbot.BotState.get_current_pos(context)
      assert newx == 1000
    end

    test "moves to a location defered by an offset", %{cs_context: context} do
      location = %Ast{kind: "coordinate", args: %{x: 1000, y: 0, z: 0}, body: []}
      offset = %Ast{kind: "coordinate", args: %{x: 500, y: 0, z: 0}, body: []}
      Command.move_absolute(%{speed: 8000, offset: offset, location: location}, [], context)
      Process.sleep(100) # wait for serial to catch up
      [newx, newy, newz] = Farmbot.BotState.get_current_pos(context)
      assert newx == 1500
      assert newy == 0
      assert newz == 0
    end

    test "moves to a bad *plant* location", %{cs_context: context} do
      [_curx, _cury, _curz] = Farmbot.BotState.get_current_pos(context)
      location = %Ast{kind: "point",
                      args: %{pointer_type: "Plant", pointer_id: 123},
                      body: []}
      offset   = %Ast{kind: "coordinate",
                      args: %{x: 0, y: 0, z: 0},
                      body: []}
      args     = %{speed:    8000,
                   offset:   offset,
                   location: location}
      assert_raise RuntimeError, "Can't find Plant with ID 123", fn ->
        Command.move_absolute(args, [], context)
      end
    end

    test "moves to a good plant", %{cs_context: context} do
      json          = Helpers.read_json("points.json")
      {:ok, db_pid} = DB.start_link(context, [])
      context       = %{context | database: db_pid}
      :ok           = Helpers.seed_db(context, Point, json)
      item          = List.first(json)

      type          = item["pointer_type"]
      id            = item["id"]

      location      = %Ast{kind: "point", args: %{pointer_type: type, pointer_id: id}, body: []}
      offset        = %Ast{kind: "coordinate", args: %{x: 0, y: 0, z: 0}, body: []}
      Command.move_absolute(%{speed: 8000, offset: offset, location: location}, [], context)

      Process.sleep(100) # wait for serial to catch up
      [x, y, z]     = Farmbot.BotState.get_current_pos(context)
      assert x == item["x"]
      assert y == item["y"]
      assert z == item["z"]

    end
  end

end
