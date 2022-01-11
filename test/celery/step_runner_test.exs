defmodule FarmbotOS.Celery.StepRunnerTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.Celery.StepRunner

  setup :verify_on_exit!

  test "execute(state, fun)" do
    fake_state = %{informational_settings: %{locked_at: 11}}

    expect(FarmbotOS.BotState, :fetch, 1, fn ->
      fake_state
    end)

    state = %{start_time: 10, listener: self(), tag: "My Tag"}
    fun = fn -> :noop end
    actual = StepRunner.execute(state, fun)
    err = "Canceled sequence due to emergency lock."
    expected = {:error, err}
    assert actual == expected
    assert_receive {:csvm_done, "My Tag", {:error, ^err}}
  end
end
