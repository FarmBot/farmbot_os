defmodule Serial.Supervisor do
  @moduledoc false
  def start_link(_args) do
    import Supervisor.Spec
    children = [worker(Serial.Handler, [[]], restart: :permanent)]
    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end
end
