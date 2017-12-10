defmodule Farmbot.Test.Authorization do
  @moduledoc "Implementation for authorization."
  @behaviour Farmbot.Bootstrap.Authorization

  def authorize(_email, _password, _server) do
    tkn = Application.get_env(:farmbot, :authorization)[:token]

    case tkn do
      token when is_binary(tkn) -> {:ok, token}
      _ -> {:error, "no token"}
    end
  end
end
