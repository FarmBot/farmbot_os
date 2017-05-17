defmodule Farmbot.CeleryScript.Command.SyncTest do
  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command
  alias Farmbot.Database
  alias Farmbot.TestHelpers
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  require IEx

  setup_all do
    token = TestHelpers.login()
    [token: token]
  end

  test "sync" do
    id           = "random thing that should be a uuid"
    json         = ~s"{ \"kind\": \"sync\", \"args\": {} }"
    before_state = :sys.get_state(Database)
    before_count = Enum.count(before_state.all)

    use_cassette "sync/corner_case" do
      json |> Poison.decode! |> Ast.parse |> Command.do_command
      after_state  = :sys.get_state(Database)
      after_count  = Enum.count(after_state.all)

      # assert(before_count < after_count)
    end
      IEx.pry
      assert(false)
  end
end
