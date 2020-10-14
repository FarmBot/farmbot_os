defmodule FarmbotExt.Bootstrap.DropPasswordTaskTest do
  require Helpers

  use ExUnit.Case
  use Mimic

  setup :verify_on_exit!
  setup :set_mimic_global

  alias FarmbotExt.Bootstrap.{
    DropPasswordTask,
    Authorization,
    DropPasswordSupport
  }

  test "drop_password" do
    expect(Authorization, :authorize_with_password_v2, 1, fn _email, _pw, _server ->
      {:ok, {[], "test_secret"}}
    end)

    expect(DropPasswordSupport, :set_secret, 1, fn secret ->
      assert secret == "test_secret"
      %{email: "email", password: "password", server: "server"}
    end)

    {:ok, pid} = DropPasswordTask.start_link([], [])
    Helpers.wait_for(pid)
  end

  test "drop_password (nil)" do
    result = DropPasswordTask.drop_password(%{password: nil}, %{})
    assert result == {:noreply, %{}, :hibernate}
  end
end
