defmodule FarmbotCore.BotStateNG.DeleteGeneratorTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.BotStateNG.DeleteGenerator

  describe "ecto integration" do
    test "ecto deletions are included"
  end

  test "deleting a key creates a list of deleted values" do
    initial = %{
      a: "string",
      aa: "string",
      b: false,
      bb: false,
      c: 1.0,
      cc: 1.0,
      d: nil,
      dd: nil,
      nested: %{
        e: "gnirts",
        ee: "gnirts",
        f: true,
        ff: true,
        g: 2.0,
        gg: 2.0,
        h: nil,
        hh: nil,
        deeply: %{
          i: "hello",
          ii: "hello",
          j: false,
          jj: false,
          k: 3.0,
          kk: 3.0,
          l: nil,
          ll: nil
        }
      }
    }

    new = %{
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

    deletes = DeleteGenerator.deletes(initial, new)
    assert [:aa] in deletes
    assert [:bb] in deletes
    assert [:cc] in deletes
    assert [:dd] in deletes
    assert [:nested, :ee] in deletes
    assert [:nested, :ff] in deletes
    assert [:nested, :gg] in deletes
    assert [:nested, :hh] in deletes
    assert [:nested, :deeply, :ii] in deletes
    assert [:nested, :deeply, :jj] in deletes
    assert [:nested, :deeply, :kk] in deletes
    assert [:nested, :deeply, :ll] in deletes
  end
end
