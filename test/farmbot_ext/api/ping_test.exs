defmodule FarmbotOS.API.PingTest do
  require Helpers
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  setup :set_mimic_global
  alias FarmbotOS.API.Ping
  alias FarmbotOS.APIFetcher

  test "random_ms/1" do
    results =
      0..99
      |> Enum.map(fn _ -> Ping.random_ms() end)
      |> Enum.sort()

    min = Enum.at(results, 0)
    max = Enum.at(results, 99)
    assert min > 900_000
    assert max < 1_200_001
  end

  test "ping_after/1" do
    expect(FarmbotOS.Time, :send_after, 1, fn pid, :ping, ms ->
      assert ms == 1234
      assert pid == self()
    end)

    Ping.ping_after(1234)
  end

  test "handle_response/3 (OK)" do
    fake_state = %{timer: nil, failures: 999}
    expected = {:noreply, %{timer: :timer, failures: 0}}
    assert expected == Ping.handle_response({:ok, nil}, fake_state, :timer)
  end

  test "handle_response/3 (Error / misc)" do
    fake_state = %{timer: nil, failures: 0}
    expected = {:noreply, %{timer: :timer, failures: 1}}
    Helpers.expect_log("Ping failed. {:error, nil}")
    assert expected == Ping.handle_response({:error, nil}, fake_state, :timer)
  end

  test "handle_info/1 (sending a ping)" do
    Helpers.use_fake_jwt()

    expect(APIFetcher, :get, 1, fn _client, url ->
      assert url == "/api/device"
    end)

    expect(FarmbotOS.Time, :send_after, 1, fn _pid, :ping, _ms ->
      :this_is_my_timer
    end)

    fake_state = %{timer: nil, failures: 0}

    result = Ping.handle_info(:ping, fake_state)

    assert {:noreply, %{failures: 1, timer: :this_is_my_timer}} == result
  end

  test "server initialization" do
    {:ok, pid} = Ping.start_link(nil, [])
    assert is_pid(pid)
    state = :sys.get_state(pid)
    %Ping{failures: 0, timer: timer} = state
    Process.cancel_timer(timer)
    Process.exit(pid, :normal)
  end
end
