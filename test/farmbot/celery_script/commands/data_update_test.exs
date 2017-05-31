defmodule Farmbot.CeleryScript.Command.DataUpdateTest do
  use ExUnit.Case, async: false

  alias Farmbot.CeleryScript.{Command, Ast}
  alias Farmbot.Database, as: DB
  alias DB.Syncable.Point
  alias Farmbot.Test.Helpers
  alias Command.DataUpdate

  setup_all do
    json          = Helpers.read_json("points.json")
    context       = Farmbot.Context.new()
    {:ok, db_pid} = DB.start_link(context, [])
    context       = %{context | database: db_pid}
    :ok           = Helpers.seed_db(context, Point, json)
    [
      json: json,
      cs_context: context
    ]
  end

  setup context do
    DB.unset_awaiting(context.cs_context, Point)
  end

  test "data_updates causes awaiting to be true.", context do
    ast = ast("add", [pair("Point", "*")])

    old = DB.get_awaiting(context.cs_context, Point)
    refute(old)

    DataUpdate.run(ast.args, ast.body, context.cs_context)

    new = DB.get_awaiting(context.cs_context, Point)
    assert(new)
  end

  def ast(verb, pairs) do
    %Ast{kind: "data_update", args: %{value: verb}, body: pairs}
  end

  def pair(mod, thing),
    do: %Ast{kind: "pair", args: %{label: mod, value: thing}, body: []}

end
