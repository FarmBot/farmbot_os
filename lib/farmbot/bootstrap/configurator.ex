defmodule Farmbot.Bootstrap.Configurator do
  use GenServer
  def start_link(_, opts) do
    creds = [
      email: "connor@farmbot.io",
      password: "password123",
      server: "https://staging.farmbot.io"
    ]
    Application.put_env(:farmbot, :authorization, creds)
    :ignore
  end
end
