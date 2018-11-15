defmodule Farmbot.OS do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Farmbot.System.Init.Supervisor, []},
      {Farmbot.System.CoreStart, []},
      {Farmbot.Platform.Supervisor, []},
      {Farmbot.System.ExtStart, []},
      {Farmbot.EasterEggs, []},
    ]
    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
