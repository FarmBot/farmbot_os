defmodule Farmbot.Database.Syncable.Regimen do
  @moduledoc """
    A Regimen from the Farmbot API.
  """

  alias Farmbot.{Context, Database}
  alias Database.Syncable
  use Syncable, model: [
    :regimen_items
  ], endpoint: {"/regimens", "/regimens"}

  defimpl Farmbot.FarmEvent.Executer, for: __MODULE__ do
    def execute_event(regimen, %Context{} = ctx, now) do
      {:ok, _pid} = Farmbot.Regimen.Supervisor.add_child(ctx, regimen, now)
    end
  end
end
