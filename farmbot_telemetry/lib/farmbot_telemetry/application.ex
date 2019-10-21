defmodule FarmbotTelemetry.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  alias FarmbotTelemetry.LogHandler

  alias FarmbotTelemetry.{
    AMQPEventClass,
    DNSEventClass,
    HTTPEventClass,
    NetworkEventClass
  }

  use Application

  def start(_type, _args) do
    children =
      for class <- [AMQPEventClass, DNSEventClass, HTTPEventClass, NetworkEventClass] do
        {FarmbotTelemetry,
         [
           class: class,
           handler_id: "#{class}-LogHandler",
           handler: &LogHandler.handle_event/4,
           config: [level: :info]
         ]}
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FarmbotTelemetry.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
