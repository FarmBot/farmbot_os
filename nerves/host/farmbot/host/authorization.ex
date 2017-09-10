defmodule Farmbot.Host.Authorization do
  @moduledoc "Host implementation for Farmbot Authorization"
  @behaviour Farmbot.Bootstrap.Authorization

  def authorize(_email, _password, _server) do
    {:ok, "this wont work"}
  end
end
