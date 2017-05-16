defmodule Farmbot.CeleryScript.Command.DataUpdateTest do
  use ExUnit.Case, async: false

  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command
  alias Farmbot.Database, as: DB
  alias DB.Syncable.Point
  alias Farmbot.TestHelpers
  alias Farmbot.CeleryScript.Command.DataUpdate
  require IEx


  setup_all do
    # TestHelpers.login()
    json = TestHelpers.read_json("points.json")

    Farmbot.TestHelpers.seed_db(Point, json)
    :ok
    [json: json]
  end

  test "data update add single module", context do
    item  = List.first(context.json)
    id    = item["id"]
    ast   = ast("add", [pair("Point", id)])
    old_state = :sys.get_state(DB)
    old   = DB.get_awaiting(Point, :add)

    Command.do_command(ast)
    Process.sleep(4000)
    new_state = :sys.get_state(DB)
    new = DB.get_awaiting(Point, :add)
    assert Enum.count(new) > Enum.count(old)
  end

  test "data update all of a module" do
    # ast = ast(:add, [pair("Point", "*")])
  end

  test "data update delete" do
  end

  test "data update update" do

  end

  def ast(verb, pairs) do
    %Ast{kind: "data_update", args: %{value: verb}, body: pairs}
  end

  def pair(mod, thing),
    do: %Ast{kind: "pair", args: %{label: mod, value: thing}, body: []}

end
