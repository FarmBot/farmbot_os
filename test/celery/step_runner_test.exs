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
    # execute/2 must not notify the listener itself; do_step/2 does that.
    refute_received {:csvm_done, _, _}
  end

  test "a failing step sends exactly one :csvm_done" do
    stub(FarmbotOS.BotState, :fetch, fn ->
      %{informational_settings: %{locked_at: 0}}
    end)

    state = %{start_time: 10, listener: self(), tag: "My Tag"}
    StepRunner.do_step(state, [fn -> raise "boom" end, fn -> :never_runs end])

    assert_received {:csvm_done, "My Tag", {:error, _}}
    refute_received {:csvm_done, _, _}
  end

  test "a successful sequence sends exactly one :csvm_done" do
    stub(FarmbotOS.BotState, :fetch, fn ->
      %{informational_settings: %{locked_at: 0}}
    end)

    state = %{start_time: 10, listener: self(), tag: "My Tag"}
    StepRunner.do_step(state, [fn -> :ok end, fn -> :ok end])

    assert_received {:csvm_done, "My Tag", :ok}
    refute_received {:csvm_done, _, _}
  end
end
