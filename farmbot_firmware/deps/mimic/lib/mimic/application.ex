defmodule Mimic.Application do
  use Application
  alias Mimic.{Cover, Server}
  @moduledoc false

  def start(_, _) do
    Cover.export_private_functions()
    children = [Server]
    Supervisor.start_link(children, name: Mimic.Supervisor, strategy: :one_for_one)
  end
end
