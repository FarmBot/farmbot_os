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

  setup do
    DB.unset_awaiting(Point)
  end

  # test "data_update add single resource", context do
  #   item  = List.first(context.json)
  #   id    = item["id"]
  #   ast   = ast("add", [pair("Point", id)])
  #   old   = DB.get_awaiting(Point, :add)
  #
  #   Command.do_command(ast)
  #
  #   new = DB.get_awaiting(Point, :add)
  #   assert Enum.count(new) > Enum.count(old)
  # end

  test "data_updates causes awaiting to be true." do
    ast = ast("add", [pair("Point", "*")])

    old = DB.get_awaiting(Point)
    refute(old)

    Command.do_command(ast)
    new = DB.get_awaiting(Point)
    assert(new)
  end

  def ast(verb, pairs) do
    %Ast{kind: "data_update", args: %{value: verb}, body: pairs}
  end

  def pair(mod, thing),
    do: %Ast{kind: "pair", args: %{label: mod, value: thing}, body: []}

end
