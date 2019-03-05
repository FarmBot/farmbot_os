defmodule FarmbotCore.BotStateNG.ChangeGeneratorTest do
  use ExUnit.Case
  alias FarmbotCore.BotStateNG.ChangeGenerator
  alias FarmbotCore.BotState

  describe "ecto integration" do
    {:ok, bot_state} = BotState.start_link([], [])
    _initial = BotState.subscribe(bot_state)
    :ok = BotState.set_position(bot_state, 1, 2, 3)

    changes =
      receive do
        {BotState, change} -> ChangeGenerator.changes(change)
      after
        100 -> raise(:timeout)
      end

    assert {[:location_data, :position, :x], 1.0} in changes
    assert {[:location_data, :position, :y], 2.0} in changes
    assert {[:location_data, :position, :z], 3.0} in changes
  end

  test "returns instructions for all data" do
    initial = %{
      a: "string",
      b: false,
      c: 1.0,
      d: nil,
      nested: %{
        e: "gnirts",
        f: true,
        g: 2.0,
        h: nil,
        deeply: %{
          i: "hello",
          j: false,
          k: 3.0,
          l: nil
        }
      }
    }

    changes = ChangeGenerator.changes(initial)
    assert {[:a], "string"} in changes
    assert {[:b], false} in changes
    assert {[:c], 1.0} in changes
    assert {[:d], nil} in changes

    assert {[:nested, :e], "gnirts"} in changes
    assert {[:nested, :f], true} in changes
    assert {[:nested, :g], 2.0} in changes
    assert {[:nested, :h], nil} in changes

    assert {[:nested, :deeply, :i], "hello"} in changes
    assert {[:nested, :deeply, :j], false} in changes
    assert {[:nested, :deeply, :k], 3.0} in changes
    assert {[:nested, :deeply, :l], nil} in changes
  end

  test "raises on lists" do
    assert_raise RuntimeError, "no lists", fn ->
      ChangeGenerator.changes(%{some_list: ["a", "b", "c"]})
    end
  end

  test "raises on atoms" do
    assert_raise RuntimeError, "unknown data: :a", fn ->
      ChangeGenerator.changes(%{some_atom: :a})
    end
  end
end
