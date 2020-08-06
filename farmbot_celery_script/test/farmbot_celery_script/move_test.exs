defmodule FarmbotCeleryScript.MoveTest do
  use ExUnit.Case, async: false
  use Mimic
  alias FarmbotCeleryScript.AST

  alias FarmbotCeleryScript.SysCalls, warn: false

  setup :verify_on_exit!

  test "move" do
    "test/fixtures/move.json"
    |> File.read!()
    |> Jason.decode!()
    |> AST.decode()
  end
end
