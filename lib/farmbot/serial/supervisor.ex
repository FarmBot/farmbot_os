defmodule Farmbot.Serial.Supervisor do
  @moduledoc "Supervisor for serial services."
  alias Farmbot.Context
  alias Farmbot.Serial.Handler.OpenTTY
  use   Context.Supervisor

  def init(%Context{} = ctx) do
    children = [
      worker(Task, [OpenTTY, :open_ttys, [ctx, __MODULE__]], restart: :transient),
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
