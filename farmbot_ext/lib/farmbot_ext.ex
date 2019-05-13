defmodule FarmbotExt do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  # Fetches a swappable implementation from application config.
  # We use this helper to find modules (usually I/O handlers) that will change
  # based on the environment, eg: test vs. prod. "default" is the default module
  # that you would expect to use in prod.
  def fetch_impl!(mod, key, default) do
    mock = Application.get_env(:farmbot_ext, mod)[key]
    mock || default
  end

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      FarmbotExt.Bootstrap
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
