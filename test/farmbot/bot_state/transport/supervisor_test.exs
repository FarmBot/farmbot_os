defmodule Farmbot.BotState.Transport.SupervisorTest do
  @moduledoc "Tests the transport supervisor."
  alias Farmbot.BotState.Transport.Supervisor, as: TPSup

  use ExUnit.Case, async: false

  setup_all do
    {:ok, bot_state_tracker} = Farmbot.BotState.start_link()
    token = "blah blah blah"
    [bot_state_tracker: bot_state_tracker, token: token]
  end

  test "starts a transport supervisor with no children", ctx do
    Application.put_env(:farmbot, :transport, [])

    {:ok, transport_sup} = TPSup.start_link(ctx.token, ctx.bot_state_tracker, [])
    assert Supervisor.which_children(transport_sup) == []
  end

  defmodule TestTransport do
    @moduledoc false
    use GenServer

    def start_link(token, bot_state_tracker) do
      GenServer.start_link(__MODULE__, [token, bot_state_tracker], name: __MODULE__)
    end

    def log(_), do: :ok
    def emit(_), do: :ok
  end

  test "starts a transport supervisor with some children", ctx do
    child = TestTransport
    Application.put_env(:farmbot, :transport, [child])

    {:ok, _tp_sup} = TPSup.start_link(ctx.token, ctx.bot_state_tracker, [])
    assert is_pid(Process.whereis(TestTransport))
    assert :sys.get_state(TestTransport) == [ctx.token, ctx.bot_state_tracker]
  end
end
