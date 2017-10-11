defmodule Farmbot.Bootstrap.AuthorizationTest do
  @moduledoc "Tests the default authorization implementation"
  alias Farmbot.Bootstrap.Authorization, as: Auth
  use ExUnit.Case

  @moduletag :farmbot_api

  setup do
    email =
      Application.get_env(:farmbot, :authorization)[:email] ||
        raise Auth.Error, "No email provided."

    pass =
      Application.get_env(:farmbot, :authorization)[:password] ||
        raise Auth.Error, "No password provided."

    server =
      Application.get_env(:farmbot, :authorization)[:server] ||
        raise Auth.Error, "No server provided."

    [email: email, password: pass, server: server]
  end

  test "Authorizes with the farmbot web api.", ctx do
    res = Auth.authorize(ctx.email, ctx.password, ctx.server)
    assert match?({:ok, _}, res)
    {:ok, bin_tkn} = res
    tkn = Farmbot.Jwt.decode!(bin_tkn)
    assert tkn.bot == "device_2"
  end

  test "gives a nice error on bad credentials.", ctx do
    res = Auth.authorize(ctx.email, ctx.password, "https://your.farmbot.io/")
    assert match?({:error, _}, res)
    {:error, message} = res
    assert message == "Failed to connect to your.farmbot.io"

    res = Auth.authorize("yolo@mtv.org", "123password", ctx.server)
    assert match?({:error, _}, res)
    {:error, message} = res
    # This shoud _probably_ be fixed on the API.
    assert message ==
             "Failed to authorize with the Farmbot web application at: #{ctx.server} with code: #{
               422
             }"
  end
end
