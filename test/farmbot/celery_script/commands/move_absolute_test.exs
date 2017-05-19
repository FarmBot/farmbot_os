defmodule Farmbot.CeleryScript.Command.MoveAbsoluteTest do
  alias Farmbot.CeleryScript.{Command, Ast}
  use Farmbot.Test.Helpers.SerialTemplate, async: false

  describe "move_absolute" do
    test "makes sure we have serial", %{cs_context: context} do
      assert Farmbot.Serial.Handler.available?(context.serial) == true
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
                      args: %{point_type: "Plant", point_id: 123},
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
      {:ok, db_pid} = DB.start_link([])
      :ok           = Helpers.seed_db(db_pid, Point, json)
      context       = Ast.Context.new()

      # TODO: Insert bogus point or whatevs.
    end
  end

end
