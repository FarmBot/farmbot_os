defmodule Farmbot.Farmware.RuntimeTest do
  @moduledoc false
  alias Farmbot.{Farmware, Context, CeleryScript}
  alias Farmbot.CeleryScript.Command.Nothing
  alias Farmbot.Farmware.Runtime
  import Mock
  use ExUnit.Case, async: false

  test_with_mock "Runs a farmware", Nothing, [:passthrough], [] do
    json_stuff = Poison.encode!(%CeleryScript.Ast{
      kind: "nothing",
      args: %{},
      body: []
    })
    fake_fw = %Farmware{
      path:       "/tmp/",
      executable: "bash",
      uuid:       Nerves.Lib.UUID.bingenerate(),
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
    context = Context.new()
    Farmbot.Tests.HTTPTemplate.replace_auth_state(context)

    Runtime.execute(context, fake_fw)
    assert called Nothing.run(%{}, [], :_)
  end
end
