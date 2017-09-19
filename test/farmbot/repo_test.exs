defmodule Farmbot.RepoTest do
  @moduledoc "Tests the Farmbot Repo"

  use ExUnit.Case

  test "ensures all syncables implement behaviour" do
    modules = Farmbot.Repo.syncables()
    assert(Enum.all? modules, fn(mod) ->
      assert Code.ensure_loaded(mod)
      assert function_exported?(mod, :sync!, 1)
    end)
  end
end
