defmodule Farmbot.Farmware.RuntimeTest do
  @moduledoc false
  use ExUnit.Case, async: false
  alias Farmbot.{Farmware, Context, CeleryScript}
  alias Farmbot.Farmware.Runtime

  test "Runs a farmware" do
    json_stuff = Poison.encode!(%CeleryScript.Ast{
      kind: "nothing",
      args: %{},
      body: []
    })
    fake_fw = %Farmware{
      executable: "echo",
      uuid:       Nerves.Lib.UUID.bingenerate(),
      name:       "spectrometer",
      url:        "",
      args:       [json_stuff],
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
    wow     = Runtime.execute(context, fake_fw)
  end
end
