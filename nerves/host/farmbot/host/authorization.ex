defmodule Farmbot.Host.Authorization do
  @moduledoc "Host implementation for Farmbot Authorization"
  @behaviour Farmbot.Bootstrap.Authorization

  def authorize(email, password, server) do
    {:ok, "this wont work"}
  end
end
