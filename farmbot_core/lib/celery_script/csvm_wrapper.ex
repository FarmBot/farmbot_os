defmodule Farmbot.CeleryScript.CsvmWrapper do
  @moduledoc false
  @io_layer Application.get_env(:farmbot_core, :behaviour)[:celery_script_io_layer]
  @io_layer || Mix.raise("No celery_script IO layer!")

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end


  def start_link(_args) do
    Csvm.start_link([io_layer: &@io_layer.handle_io/1], name: Csvm)
  end
end
