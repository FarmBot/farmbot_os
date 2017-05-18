defmodule Farmbot.BotState.ConfigurationTest do
  use ExUnit.Case, async: false
  alias Farmbot.CeleryScript.Ast.Context

  setup_all do
    cs_context = Context.new()
    [cs_context: cs_context]
  end

  test "makes sure we dont mess state up with bad calls or casts", context do
    before_call = get_state(context.cs_context)
    resp = GenServer.call(context.cs_context.configuration, :do_a_barrel_roll)
    after_call = get_state(context.cs_context)
    assert(resp == :unhandled)
    assert(after_call == before_call)

    GenServer.cast(context.cs_context.configuration, :bot_net_start)
    after_cast = get_state(context.cs_context)
    assert(before_call == after_cast)
  end

  test "updates a setting inside informational settings", context do
    conf = context.cs_context.configuration
    old  = get_state(context.cs_context)
    GenServer.cast(conf, {:update_info, :i_know_this, :its_unix})
    # maybe bug? change this cast to a call?
    new = get_state(context.cs_context)
    assert(old != new)
  end

  defp get_state(ctx) do
    Process.sleep(10)
    :sys.get_state(ctx.monitor).state |> Map.fetch!(:configuration)
  end
end
