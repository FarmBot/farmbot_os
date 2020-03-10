defmodule FarmbotExt do
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children(), opts)
  end

  # This only exists because I was getting too many crashed
  # supervisor reports in the test suite (distraction from
  # real test failures).
  def children do
    config = Application.get_env(:farmbot_ext, __MODULE__) || []
    Keyword.get(config, :children, [FarmbotExt.Bootstrap])
  end
end
