defmodule Farmbot.CeleryScript.Command.DataUpdateTest do
  use ExUnit.Case, async: false

  alias Farmbot.CeleryScript.{Command, Ast}
  alias Farmbot.Database, as: DB
  alias DB.Syncable.Point
  alias Farmbot.Test.Helpers
  alias Command.DataUpdate
  require IEx


  setup_all do
    json          = Helpers.read_json("points.json")
    context = Farmbot.Context.new()
    {:ok, db_pid} = DB.start_link(context, [])
    :ok           = Helpers.seed_db(db_pid, Point, json)
    [
      json: json,
      db_pid: db_pid,
      cs_context: %{context | database: db_pid}
    ]
  end

  setup context do
    DB.unset_awaiting(context.db_pid, Point)
  end

  test "data_updates causes awaiting to be true.", context do
    ast = ast("add", [pair("Point", "*")])

    old = DB.get_awaiting(context.db_pid, Point)
    refute(old)

    DataUpdate.run(ast.args, ast.body, context.cs_context)

    new = DB.get_awaiting(context.db_pid, Point)
    assert(new)
  end

  def ast(verb, pairs) do
    %Ast{kind: "data_update", args: %{value: verb}, body: pairs}
  end

  def pair(mod, thing),
    do: %Ast{kind: "pair", args: %{label: mod, value: thing}, body: []}

end
