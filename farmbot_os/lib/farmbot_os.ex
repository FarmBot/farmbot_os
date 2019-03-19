defmodule FarmbotOS do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {FarmbotOS.Init.Supervisor, []},
      {FarmbotOS.Platform.Supervisor, []},
      {FarmbotOS.EasterEggs, []}
    ]

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
