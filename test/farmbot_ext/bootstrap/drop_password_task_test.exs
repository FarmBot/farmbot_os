defmodule FarmbotOS.Bootstrap.DropPasswordTaskTest do
  require Helpers

  use ExUnit.Case
  use Mimic

  setup :verify_on_exit!
  setup :set_mimic_global

  alias FarmbotOS.Bootstrap.{
    DropPasswordTask,
    Authorization,
    DropPasswordSupport
  }

  @fake_params %{email: "email", password: "password", server: "server"}

  test "drop_password" do
    expect(Authorization, :authorize_with_password_v2, 1, fn _email,
                                                             _pw,
                                                             _server ->
      {:ok, {[], "test_secret"}}
    end)

    expect(DropPasswordSupport, :set_secret, 1, fn secret ->
      assert secret == "test_secret"
      @fake_params
    end)

    {:ok, pid} = DropPasswordTask.start_link([], [])
    Helpers.wait_for(pid)
  end

  test "drop_password (nil)" do
    result = DropPasswordTask.drop_password(%{password: nil}, %{})
    assert result == {:noreply, %{}, :hibernate}
  end

  test "drop_password (error)" do
    state = %{backoff: 12345, timer: nil}

    expect(FarmbotOS.Time, :send_after, 1, fn _pid, :checkup, _state ->
      :fake_timer
    end)

    result = DropPasswordTask.drop_password(@fake_params, state)
    assert result == {:noreply, %{backoff: 13345, timer: :fake_timer}}
  end
end
