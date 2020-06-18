defmodule FarmbotExt.BootstrapTest do
  require Helpers
  use ExUnit.Case, async: false
  use Mimic
  alias FarmbotExt.Bootstrap
  setup :verify_on_exit!
  setup :set_mimic_global

  test "performs a factory reset if the email is wrong" do
    expect(FarmbotExt.Bootstrap.Authorization, :authorize_with_password, 1, fn
      _email, _password, _server ->
        {:error, "Intentional failure."}
    end)

    expect(FarmbotCeleryScript.SysCalls, :factory_reset, 1, fn "farmbot_os" -> :ok end)
    assert Bootstrap.try_auth("", "", "", "") == {:noreply, nil, 5000}
  end
end
