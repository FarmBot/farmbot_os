defmodule FarmbotExt do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  # Fetches a swappable implementation from application config.
  # We use this helper to find modules (usually I/O handlers) that will change
  # based on the environment, eg: test vs. prod.
  def fetch_impl!(mod, key) do
    Application.get_env(:farmbot_ext, mod)[key] ||
      Mix.raise("""
      No default #{to_string(key)} implementation was provided.

        config :farmbot_ext,
          #{Macro.to_string(mod)},
          [#{to_string(key)}: #{Macro.to_string(mod)}.ModuleThatImplementsIt]
      """)
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
