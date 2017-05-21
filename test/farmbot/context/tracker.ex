defmodule Farmbot.Context.TrackerTest do
  use ExUnit.Case, async: true
  alias Farmbot.Context.Tracker

  test "builds and tracks a context" do
    context = Context.new()
    random_key = Map.from_struct |> Map.delete(:data_stack) |> Map.keys |> Enum.random
    context = %{ context | random_key => :some_cool_value}
    {:ok, tracker} = Tracker.start_link(context, [])

    assert is_pid(tracker)
    assert is_map(context)
    assert is_atom(random_key)

    ctx = Tracker.get_context(tracker)
    assert is_map(ctx)
    assert Map.get(ctx, random_key) == :some_cool_value
    assert ctx == context

  end
endf
