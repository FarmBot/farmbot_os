defmodule Farmbot.Farmware.RuntimeTest do
  @moduledoc false
  alias Farmbot.{Farmware, Context, CeleryScript}
  alias Farmbot.Farmware.Runtime
  use ExUnit.Case, async: false

  setup_all do
    context      = Context.new()
    new_context  = Farmbot.Test.Helpers.Context.replace_http(context)
    {:ok, auth}  = Farmbot.Auth.start_link(new_context, [])
    new_context1 = %{new_context | auth: auth}
    Farmbot.Auth.try_log_in!(new_context1.auth)
    [cs_context: new_context1]
  end

  test "Runs a farmware", %{cs_context: ctx} do
    nothing_node = %CeleryScript.Ast{
      kind: "nothing",
      args: %{},
      body: []
    }
    json_stuff   = Poison.encode!(nothing_node)

    fake_fw = %Farmware{
      path:       "/tmp/",
      executable: "bash",
      uuid:       UUID.uuid1(),
      name:       "spectrometer",
      url:        "",
      args:       ["-c", "echo $BEGIN_CELERYSCRIPT #{inspect json_stuff}"],
      meta:       %{
        min_os_version_major: "1" ,
        description:          "This is a fixture farmware for tests.",
        language:             "python",
        version:              "1.0.0",
        author:               "BLAH Blah",
        zip:                  "hello.zip"
      }
    }

    new_context             = Runtime.execute(ctx, fake_fw)
    {nothing, new_context1} = Context.pop_data(new_context)
    assert nothing     == nothing_node
    assert new_context != new_context1
  end
end
