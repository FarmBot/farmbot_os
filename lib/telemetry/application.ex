defmodule FarmbotTelemetry.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def config do
    user_defined = Application.get_all_env(:farmbot)

    Keyword.merge(
      [access: :read_write, type: :set, file: '/tmp/farmbot_telemetry.dets'],
      user_defined
    )
  end

  def start(_type, _args) do
    {:ok, :farmbot} = :dets.open_file(:farmbot, config())
    children = []

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FarmbotTelemetry.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
