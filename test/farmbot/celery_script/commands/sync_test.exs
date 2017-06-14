defmodule Farmbot.CeleryScript.Command.SyncTest do
  use ExUnit.Case, async: false
  alias Farmbot.{Context, Database}
  alias Farmbot.CeleryScript.Command.Sync
  alias Farmbot.Test.Helpers

  setup_all do
    ctx = Context.new()
    {:ok, db}   = Database.start_link(ctx, [])
    # {:ok, auth} = Farmbot.Auth.start_link(ctx, [])
    ctx = %{ctx | database: db}
    [cs_context: Helpers.login(ctx)]
  end
  # 
  # test "syncs the bot", %{cs_context: ctx} do
  #   db = ctx.database
  #   :ok = Database.flush(ctx)
  #
  #   use_cassette "sync/corner_case" do
  #     before_state = :sys.get_state(db)
  #     before_count = Enum.count(before_state.all)
  #
  #     Sync.run(%{}, [], ctx)
  #     after_state  = :sys.get_state(db)
  #
  #     after_count  = Enum.count(after_state.all)
  #     assert(before_count < after_count)
  #   end
  #
  # end
end
