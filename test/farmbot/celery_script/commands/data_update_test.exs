defmodule Farmbot.CeleryScript.Command.DataUpdateTest do
  use ExUnit.Case, async: false

  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command
  alias Farmbot.Database, as: DB
  alias DB.Syncable.Point
  alias Farmbot.TestHelpers
  require IEx


  setup_all do
    json = TestHelpers.read_json("points.json")
    {:ok, pid} = DB.start_link([])
    :ok        = Farmbot.TestHelpers.seed_db(pid, Point, json)

    [json: json, pid: pid]
  end

  setup context do
    DB.unset_awaiting(context.pid, Point)
  end

  test "data_updates causes awaiting to be true.", context do
    ast = ast("add", [pair("Point", "*")])

    old = DB.get_awaiting(context.pid, Point)
    refute(old)

    Command.do_command(ast)
    new = DB.get_awaiting(context.pid, Point)
    IEx.pry
    assert(new)
  end

  def ast(verb, pairs) do
    %Ast{kind: "data_update", args: %{value: verb}, body: pairs}
  end

  def pair(mod, thing),
    do: %Ast{kind: "pair", args: %{label: mod, value: thing}, body: []}

end
