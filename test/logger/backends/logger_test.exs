defmodule Logger.Backends.FarmbotLoggerTest do
  use ExUnit.Case, async: false
  alias Farmbot.{Auth, Context}
  require Logger
  alias Farmbot.Test.Helpers

  setup_all do
    backend = Logger.Backends.FarmbotLogger

    on_exit(fn() ->
      Logger.remove_backend(backend)
    end)

    context = Context.new()
    Logger.flush()
    {:ok, _pid} = Logger.add_backend(backend)
    ok          = GenEvent.call(Logger, backend, {:context, context})
    [cs_context:   Helpers.login(context)]
  end

  test "logs fifty messages, then uploads them to the api", %{cs_context: ctx} do
    Logger.flush
    for i <- 0..51 do
      Logger.info "Farmbot can count to: #{i}"
    end
    Process.sleep(100)

    r = Farmbot.HTTP.get! ctx, "/api/logs"
    body = Poison.decode!(r.body)
    assert Enum.count(body) >= 49
  end

  test "gets the logger state" do
    Logger.flush

    Logger.info "hey world"
    state = GenEvent.call(Logger, Logger.Backends.FarmbotLogger, :get_state)
    assert is_list(state.logs)
    [log] = state.logs
    assert log.message == "hey world"
  end
end
