defmodule Farmbot.Sync.CacheTest do
  use ExUnit.Case
  alias Farmbot.Sync.Cache
  alias Farmbot.CeleryScript.Command

  test "adds stuff to the cache then clears it" do
    old = Cache.get_out_of_sync
    cs = ~s"""
    {
      "kind": "data_update",
      "args": {
        "value": "updated"
      },
      "body": [
        {
          "kind": "pair",
          "args": {
            "label": "sequence",
            "value": "*"
          }
        },
        {
          "kind": "pair",
          "args": {
            "label": "regimen",
            "value": "456"
          }
        }
      ]
    }
    """
    cs |> Poison.decode! |> Farmbot.CeleryScript.Ast.parse |> Command.do_command
    new = Cache.get_out_of_sync
    assert old != new
    assert new == %{regimen: [updated: 456], sequence: [updated: "*"]}
    Cache.clear()
    next = Cache.get_out_of_sync
    assert new != next
    assert next == %{}
  end

end
