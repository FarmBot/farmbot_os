defmodule FarmbotExt do
  @moduledoc false

  use Application

  def start(_type, _args) do
    Supervisor.start_link(children(), opts())
  end

  def opts, do: [strategy: :one_for_one, name: __MODULE__]

  def children do
    config = Application.get_env(:farmbot_ext, __MODULE__) || []
    Keyword.get(config, :children, [FarmbotExt.Bootstrap])
  end
end
