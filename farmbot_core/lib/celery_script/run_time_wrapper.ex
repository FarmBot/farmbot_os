defmodule Farmbot.Core.CeleryScript.RunTimeWrapper do
  @moduledoc false
  alias Farmbot.CeleryScript.AST
  alias Farmbot.CeleryScript.RunTime
  @io_layer Application.get_env(:farmbot_core, :behaviour)[:celery_script_io_layer]
  @io_layer || Mix.raise("No celery_script IO layer!")

  @doc false
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, opts},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @doc false
  def start_link do
    opts = [
      process_io_layer: &handle_io/1,
      hyper_io_layer: &handle_hyper/1
    ]

    RunTime.start_link(opts)
  end

  @doc false
  def handle_io(%AST{kind: :execute_script, args: args}) do
    Farmbot.FarmwareRuntime.execute_script(args)
  end

  def handle_io(%AST{kind: kind, args: args, body: body}) do
    apply(@io_layer, kind, [args, body])
  end

  @doc false
  def handle_hyper(:emergency_lock) do
    apply(@io_layer, :emergency_lock, [%{}, []])
  end

  def handle_hyper(:emergency_unlock) do
    apply(@io_layer, :emergency_unlock, [%{}, []])
  end
end
